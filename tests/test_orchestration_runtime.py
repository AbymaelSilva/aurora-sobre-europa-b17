"""Pruebas offline de infraestructura. No Godot ni proveedores/modelos reales."""
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from types import SimpleNamespace
from unittest.mock import patch

SOURCE=Path(__file__).resolve().parents[1]

def module(name):
    spec=importlib.util.spec_from_file_location(name,SOURCE/(name+'.py'))
    value=importlib.util.module_from_spec(spec);spec.loader.exec_module(value)
    return value

class InfrastructureTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(prefix='b17-runtime-offline-')
        self.root=Path(self.tmp.name)
        self.supervisor=module('agy_coordinador');self.bridge=module('encargar_qwen')
        self.project=self.root/'godot/B17';self.project.mkdir(parents=True)
        (self.root/'planning').mkdir();(self.root/'logs').mkdir()
        self.patches=[patch.object(self.supervisor,'ROOT',self.root),patch.object(self.supervisor,'LOG',self.root/'logs/agy-coordinador'),patch.object(self.supervisor,'STATE',self.root/'logs/agy-coordinador/status.json'),patch.object(self.supervisor,'EVENT_LOG',self.root/'logs/orquestacion/runtime.log'),patch.object(self.supervisor,'PROMPT',self.root/'planning/prompt.md'),patch.object(self.bridge,'ROOT',self.root),patch.object(self.bridge,'PROJECT',self.project)]
        for p in self.patches:p.start()
        self.supervisor.LOG.mkdir()
        self.target=self.project/'core/item.gd';self.target.parent.mkdir();self.target.write_text('ORIGINAL\n')
        self.task=self.root/'planning/task.json';self.task.write_text(json.dumps({'path':'core/item.gd','brief':'test contract','test':'tests/unit.gd'}))
        (self.project/'tests').mkdir();(self.project/'tests/unit.gd').write_text('extends SceneTree\n')
    def tearDown(self):
        for p in reversed(self.patches):p.stop()
        self.tmp.cleanup()
    def response(self,*args,**kwargs):
        return io.BytesIO(json.dumps({'message':{'content':'extends RefCounted\n'}}).encode())
    def run_bridge(self,run):
        with patch.object(sys,'argv',['encargar_qwen.py',str(self.task)]),patch.object(self.bridge.urllib.request,'urlopen',self.response),patch.object(self.bridge.subprocess,'run',run):
            self.bridge.main()
    def test_failed_functional_checks_restore_original_and_never_report_delivery(self):
        def run(args,**kwargs):
            return SimpleNamespace(returncode=0,stdout='OK\n' if '--check-only' in args else 'TEST FAIL: actual regression\n',stderr='')
        with self.assertRaises(SystemExit) as raised:self.run_bridge(run)
        self.assertEqual(raised.exception.code,1)
        self.assertEqual(self.target.read_text(),'ORIGINAL\n')
        folder=next((self.root/'logs/agy-qwen').iterdir())
        self.assertEqual(json.loads((folder/'result.json').read_text())['status'],'needs_review')
        self.assertEqual(len(list(folder.glob('*.candidate.gd'))),3)
        self.assertNotIn('ENTREGADO_PARA_REVISION',(self.root/'logs/orquestacion/qwen.log').read_text())
    def test_success_logs_only_delivery_for_review_and_unique_folders(self):
        run=lambda *a,**k:SimpleNamespace(returncode=0,stdout='TEST PASS: mocked functional check\n',stderr='')
        self.run_bridge(run);self.run_bridge(run)
        folders=list((self.root/'logs/agy-qwen').iterdir())
        self.assertEqual(len(folders),2)
        for folder in folders:self.assertEqual(json.loads((folder/'result.json').read_text())['status'],'accepted_for_review')
        log=(self.root/'logs/orquestacion/qwen.log').read_text()
        self.assertEqual(log.count('ENTREGADO_PARA_REVISION'),2)
        self.assertNotIn('COMPLETADO_VERIFICADO',log)
    def test_network_failure_preserves_source_and_does_not_invent_candidate(self):
        from urllib.error import URLError
        with patch.object(sys,'argv',['encargar_qwen.py',str(self.task)]),patch.object(self.bridge.urllib.request,'urlopen',side_effect=URLError('mock offline')):
            with self.assertRaises(URLError):self.bridge.main()
        folder=next((self.root/'logs/agy-qwen').iterdir())
        self.assertEqual(self.target.read_text(),'ORIGINAL\n')
        self.assertFalse(list(folder.glob('*.candidate.gd')))
        self.assertEqual(json.loads((folder/'result.json').read_text())['status'],'blocked')
    def test_progress_counts_new_outcome_not_agent_chatter_or_duplicate_delivery(self):
        before=self.supervisor.progress_snapshot()
        log=self.root/'logs/orquestacion';log.mkdir()
        (log/'agy.log').write_text('RECIBIDO\nENTREGADO\n')
        self.assertEqual(before,self.supervisor.progress_snapshot())
        (log/'qa.log').write_text('TEST FAIL: mismatch\n')
        self.assertNotEqual(before,self.supervisor.progress_snapshot())
        result={'status':'accepted_for_review','path':'core/item.gd','sha256':'abc'}
        for name in ['first','second']:
            folder=self.root/'logs/agy-qwen'/name;folder.mkdir(parents=True);(folder/'result.json').write_text(json.dumps(result))
            snapshot=self.supervisor.progress_snapshot()
            if name=='first':first=snapshot
            else:self.assertEqual(first,snapshot)
    def test_review_wait_is_not_a_block_and_stagnation_is_visible(self):
        self.assertEqual(self.supervisor.next_round_state({'status':'awaiting_review'},False,1),('awaiting_review',1))
        self.assertEqual(self.supervisor.next_round_state({},False,1),('needs_supervisor_attention',2))
        self.assertEqual(self.supervisor.next_round_state({},True,1),('continuing',0))
    def prepare_verification(self):
        names=['test_long_mission','test_scene_mission','test_qwen_assets','test_claude_batch','test_release_acceptance','test_claude_review','test_imported_aircraft_integration','test_local_control_directions','test_manual_mission_claude']
        for name in names:(self.project/'tests'/(name+'.gd')).write_text('extends SceneTree\n')
        (self.root/'planning/AGY_ACEPTACION.md').write_text('Candidate report\n')
    def test_candidate_rejects_leaks_even_when_return_zero_and_pass_printed(self):
        self.prepare_verification()
        run=lambda *a,**k:SimpleNamespace(returncode=0,stdout='TEST PASS: mocked\n',stderr='WARNING: 2 ObjectDB instances were leaked at exit\n')
        with patch.object(self.supervisor.subprocess,'run',run):self.assertFalse(self.supervisor.verify_candidate())
        report=json.loads((self.supervisor.LOG/'candidate-verification.json').read_text())
        self.assertEqual(len(report),11)
        self.assertTrue(any(x['test']=='tests/test_local_control_directions.gd' for x in report))
    def test_candidate_requires_unchanged_sources_and_fresh_acceptance(self):
        self.prepare_verification()
        run=lambda *a,**k:SimpleNamespace(returncode=0,stdout='TEST PASS: mocked\n',stderr='')
        with patch.object(self.supervisor.subprocess,'run',run):
            self.assertTrue(self.supervisor.verify_candidate())
            self.assertFalse(self.supervisor.verify_candidate(since=time.time()+10))
        changed=False
        def mutate(*args,**kwargs):
            nonlocal changed
            if not changed:self.target.write_text('CHANGED DURING QA\n');changed=True
            return run()
        with patch.object(self.supervisor.subprocess,'run',mutate):self.assertFalse(self.supervisor.verify_candidate())
    def test_run_fake_agent_waits_for_review_and_preserves_metadata(self):
        self.supervisor.PROMPT.write_text('Mock supervisor prompt\n')
        fake=self.root/'fake_agent.py'
        fake.write_text('''import json,time\nfrom pathlib import Path\nroot=Path(__file__).parent\nprint(json.dumps({"event":"init","conversation_id":"offline-fake","init":{}}),flush=True)\nprint(json.dumps({"event":"step_update","step_update":{"step_type":"tool","step_index":1,"state":"DONE","tool_name":"view_file","tool_info":{}}}),flush=True)\ntime.sleep(0.05)\n(root/"planning/AGY_ESTADO.json").write_text(json.dumps({"status":"awaiting_review","dependency":"independent review"}))\nprint(json.dumps({"event":"result","result":{"status":"SUCCESS"}}),flush=True)\n''')
        real_popen=subprocess.Popen;states=[];original_write=self.supervisor.write_state
        def launch(*args,**kwargs):return real_popen([sys.executable,str(fake)],**kwargs)
        def record(**data):states.append(data.copy());original_write(**data)
        with patch.object(self.supervisor,'check'),patch.object(self.supervisor.subprocess,'Popen',launch),patch.object(self.supervisor,'write_state',record):self.supervisor.run()
        self.assertEqual(json.loads(self.supervisor.STATE.read_text())['status'],'awaiting_review')
        tool_state=next(x for x in states if x.get('last_tool')=='view_file')
        self.assertEqual(tool_state['goal_file'],str(self.supervisor.PROMPT))
        self.assertEqual(tool_state['conversation_id'],'offline-fake')
        self.assertIn('heartbeat_utc',tool_state)
    def test_single_instance_lock_prevents_launch(self):
        import fcntl
        lock=(self.supervisor.LOG/'coordinator.lock').open('a');fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        try:
            with patch.object(self.supervisor,'check'),patch.object(self.supervisor.subprocess,'Popen') as launch:
                self.supervisor.run();launch.assert_not_called()
        finally:lock.close()

if __name__=='__main__':unittest.main(verbosity=2)
