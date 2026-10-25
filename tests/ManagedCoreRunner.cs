using System;

public static class ManagedCoreRunner
{
    public static int Main()
    {
        try
        {
            B17.Editor.CoreChecks.CheckAll();
            Console.WriteLine("Same production core tested with genuine Unity managed math assemblies. No editor, scene, shader or input validation claimed.");
            return 0;
        }
        catch(Exception error)
        {
            Console.Error.WriteLine(error.ToString());
            return 1;
        }
    }
}
