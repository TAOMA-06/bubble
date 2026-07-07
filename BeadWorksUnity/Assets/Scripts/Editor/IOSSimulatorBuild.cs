using UnityEditor;

namespace BeadWorks.Editor
{
    public static class IOSSimulatorBuild
    {
        private const string DefaultOutputPath = "Builds/iOSSimulator";

        [MenuItem("BeadWorks/Build/iOS Simulator Xcode Project")]
        public static void BuildFromMenu()
        {
            IOSBuildExporter.Export(simulator: true, DefaultOutputPath, developmentBuild: false);
        }

        [MenuItem("BeadWorks/Build/iOS Simulator Xcode Project (Debug)")]
        public static void BuildDebugFromMenu()
        {
            IOSBuildExporter.Export(simulator: true, DefaultOutputPath, developmentBuild: true);
        }

        public static void BuildFromCommandLine()
        {
            IOSBuildExporter.Export(
                simulator: true,
                IOSBuildExporter.GetArgument("-buildOutput") ?? DefaultOutputPath,
                IOSBuildExporter.HasFlag("-developmentBuild"));
        }
    }
}
