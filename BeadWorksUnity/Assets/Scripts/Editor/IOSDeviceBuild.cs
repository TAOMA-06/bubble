using UnityEditor;

namespace BeadWorks.Editor
{
    public static class IOSDeviceBuild
    {
        private const string DefaultOutputPath = "Builds/iOSDevice";

        [MenuItem("BeadWorks/Build/iOS Device Xcode Project")]
        public static void BuildFromMenu()
        {
            IOSBuildExporter.Export(simulator: false, DefaultOutputPath, developmentBuild: false);
        }

        [MenuItem("BeadWorks/Build/iOS Device Xcode Project (Debug)")]
        public static void BuildDebugFromMenu()
        {
            IOSBuildExporter.Export(simulator: false, DefaultOutputPath, developmentBuild: true);
        }

        public static void BuildFromCommandLine()
        {
            IOSBuildExporter.Export(
                simulator: false,
                IOSBuildExporter.GetArgument("-buildOutput") ?? DefaultOutputPath,
                IOSBuildExporter.HasFlag("-developmentBuild"));
        }
    }
}
