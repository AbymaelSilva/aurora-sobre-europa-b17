using System;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace B17.Editor
{
    public static class ProjectSetup
    {
        public static void Initialize()
        {
            Directory.CreateDirectory("Assets/Scenes");
            var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
            EditorSceneManager.SaveScene(scene,"Assets/Scenes/Aurora.unity");
            EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene("Assets/Scenes/Aurora.unity",true)};
            PlayerSettings.productName="Aurora - B17";
            PlayerSettings.companyName="Aurora Project";
            PlayerSettings.defaultScreenWidth=1280;
            PlayerSettings.defaultScreenHeight=720;
            PlayerSettings.runInBackground=true;
            PlayerSettings.colorSpace=ColorSpace.Linear;
            AssetDatabase.SaveAssets();
            CoreChecks.Run();
            Debug.Log("B17_PROJECT_READY: scene and core checks completed.");
        }

        public static void BuildLinux()
        {
            Initialize();
            Directory.CreateDirectory("Builds/Linux");
            var report=BuildPipeline.BuildPlayer(new[]{"Assets/Scenes/Aurora.unity"},"Builds/Linux/Aurora.x86_64",BuildTarget.StandaloneLinux64,BuildOptions.None);
            if(report.summary.result!=UnityEditor.Build.Reporting.BuildResult.Succeeded)
                throw new Exception("Linux build failed: "+report.summary.result);
        }
    }
}
