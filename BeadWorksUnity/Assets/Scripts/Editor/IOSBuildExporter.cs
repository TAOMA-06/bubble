using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace BeadWorks.Editor
{
    internal static class IOSBuildExporter
    {
        internal const string BundleIdentifier = "com.beadworks.unity";

        internal static void Export(bool simulator, string outputPath, bool developmentBuild = false)
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
            if (Directory.Exists(fullOutputPath))
            {
                Directory.Delete(fullOutputPath, recursive: true);
            }

            Directory.CreateDirectory(fullOutputPath);

            // Clear stale iOS IL2CPP artifacts to avoid duplicate assembly names (e.g. "mscorlib 2.dll").
            var beeIosArtifacts = Path.GetFullPath(Path.Combine("Library", "Bee", "artifacts", "iOS"));
            if (Directory.Exists(beeIosArtifacts))
            {
                Directory.Delete(beeIosArtifacts, recursive: true);
            }

            EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.iOS, BuildTarget.iOS);
            ApplyCommonSettings();

            if (simulator)
            {
                ApplySimulatorSettings();
            }
            else
            {
                ApplyDeviceSettings();
            }

            EditorUserBuildSettings.development = developmentBuild;
            EditorUserBuildSettings.allowDebugging = developmentBuild;

            var options = new BuildPlayerOptions
            {
                scenes = scenes,
                locationPathName = fullOutputPath,
                target = BuildTarget.iOS,
                options = developmentBuild
                    ? BuildOptions.Development | BuildOptions.AllowDebugging
                    : BuildOptions.None
            };

            var report = BuildPipeline.BuildPlayer(options);
            var summary = report.summary;
            if (summary.result != BuildResult.Succeeded)
            {
                throw new InvalidOperationException(
                    $"{(simulator ? "Simulator" : "Device")} iOS export failed: {summary.result} " +
                    $"({summary.totalErrors} errors, {summary.totalWarnings} warnings)");
            }

            Debug.Log(
                $"[BeadWorks] iOS {(simulator ? "Simulator" : "Device")} " +
                $"{(developmentBuild ? "Debug" : "Release")} Xcode project exported to {fullOutputPath}");
        }

        private static void ApplyCommonSettings()
        {
            PlayerSettings.companyName = "BeadWorks";
            PlayerSettings.productName = "BeadWorks";
            PlayerSettings.bundleVersion = "1.0";
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.iOS, BundleIdentifier);
            PlayerSettings.iOS.targetOSVersionString = "15.0";
            PlayerSettings.SetArchitecture(BuildTargetGroup.iOS, 1);
        }

        private static void ApplySimulatorSettings()
        {
            PlayerSettings.iOS.sdkVersion = iOSSdkVersion.SimulatorSDK;
            PlayerSettings.iOS.simulatorSdkArchitecture = AppleMobileArchitectureSimulator.ARM64;
        }

        private static void ApplyDeviceSettings()
        {
            PlayerSettings.iOS.sdkVersion = iOSSdkVersion.DeviceSDK;
            PlayerSettings.SetArchitecture(BuildTargetGroup.iOS, 1);
            PlayerSettings.iOS.appleEnableAutomaticSigning = true;
        }

        internal static string GetArgument(string name)
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

        internal static bool HasFlag(string name)
        {
            return Environment.GetCommandLineArgs().Any(arg => arg == name);
        }
    }
}
