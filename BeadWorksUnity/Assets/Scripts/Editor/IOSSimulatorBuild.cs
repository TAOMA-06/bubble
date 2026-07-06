using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;

namespace BeadWorks.Editor
{
    public static class IOSSimulatorBuild
    {
        private const string DefaultOutputPath = "Builds/iOSSimulator";
        private const string BundleIdentifier = "com.beadworks.unity";

        [MenuItem("BeadWorks/Build/iOS Simulator Xcode Project")]
        public static void BuildFromMenu()
        {
            Build(DefaultOutputPath);
        }

        public static void BuildFromCommandLine()
        {
            Build(GetArgument("-buildOutput") ?? DefaultOutputPath);
        }

        private static void Build(string outputPath)
        {
            var scenes = EditorBuildSettings.scenes
                .Where(scene => scene.enabled)
                .Select(scene => scene.path)
                .ToArray();

            if (scenes.Length == 0)
            {
                throw new InvalidOperationException("No enabled scenes found in EditorBuildSettings.");
            }

            var fullOutputPath = Path.GetFullPath(outputPath);
            Directory.CreateDirectory(fullOutputPath);

            EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.iOS, BuildTarget.iOS);

            PlayerSettings.companyName = "BeadWorks";
            PlayerSettings.productName = "BeadWorks";
            PlayerSettings.bundleVersion = "1.0";
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.iOS, BundleIdentifier);
            PlayerSettings.iOS.sdkVersion = iOSSdkVersion.SimulatorSDK;
            PlayerSettings.iOS.targetOSVersionString = "15.0";

            EditorUserBuildSettings.development = true;
            EditorUserBuildSettings.allowDebugging = true;

            var options = new BuildPlayerOptions
            {
                scenes = scenes,
                locationPathName = fullOutputPath,
                target = BuildTarget.iOS,
                options = BuildOptions.Development | BuildOptions.AllowDebugging
            };

            var report = BuildPipeline.BuildPlayer(options);
            var summary = report.summary;
            if (summary.result != BuildResult.Succeeded)
            {
                throw new InvalidOperationException(
                    $"iOS Simulator export failed: {summary.result} ({summary.totalErrors} errors, {summary.totalWarnings} warnings)");
            }

            UnityEngine.Debug.Log($"[BeadWorks] iOS Simulator Xcode project exported to {fullOutputPath}");
        }

        private static string GetArgument(string name)
        {
            var args = Environment.GetCommandLineArgs();
            for (var i = 0; i < args.Length - 1; i++)
            {
                if (args[i] == name)
                {
                    return args[i + 1];
                }
            }

            return null;
        }
    }
}
