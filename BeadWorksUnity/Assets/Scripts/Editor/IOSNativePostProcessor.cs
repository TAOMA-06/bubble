using System.IO;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;
using UnityEngine;

namespace BeadWorks.Editor
{
    /// <summary>
    /// Post-processes the exported Xcode project so the native PHPicker bridge
    /// (Assets/Plugins/iOS/BeadWorksPhotoPicker.mm) has the privacy strings and
    /// framework links it needs.
    /// </summary>
    internal static class IOSNativePostProcessor
    {
        private const string PhotoLibraryUsageDescription = "用于从相册选择照片，自动生成拼豆图纸。";
        private const string PhotoLibraryAddUsageDescription = "用于将完成的拼豆作品保存到相册。";

        [PostProcessBuild(1)]
        public static void OnPostProcessBuild(BuildTarget target, string pathToBuiltProject)
        {
            if (target != BuildTarget.iOS)
            {
                return;
            }

            UpdateInfoPlist(pathToBuiltProject);
            UpdateXcodeProject(pathToBuiltProject);
        }

        private static void UpdateInfoPlist(string pathToBuiltProject)
        {
            var plistPath = Path.Combine(pathToBuiltProject, "Info.plist");
            var plist = new PlistDocument();
            plist.ReadFromFile(plistPath);

            plist.root.SetString("NSPhotoLibraryUsageDescription", PhotoLibraryUsageDescription);
            plist.root.SetString("NSPhotoLibraryAddUsageDescription", PhotoLibraryAddUsageDescription);

            plist.WriteToFile(plistPath);
            Debug.Log("[BeadWorks] Added photo library usage descriptions to Info.plist");
        }

        private static void UpdateXcodeProject(string pathToBuiltProject)
        {
            var projectPath = PBXProject.GetPBXProjectPath(pathToBuiltProject);
            var project = new PBXProject();
            project.ReadFromFile(projectPath);

            // Native plugin sources compile into the UnityFramework target; the main app
            // target link is a harmless safety net for project layouts without that split.
            var frameworkTargetGuid = project.GetUnityFrameworkTargetGuid();
            var mainTargetGuid = project.GetUnityMainTargetGuid();

            AddFrameworks(project, frameworkTargetGuid);
            AddFrameworks(project, mainTargetGuid);

            project.WriteToFile(projectPath);
            Debug.Log("[BeadWorks] Linked PhotosUI/Photos frameworks in Xcode project");
        }

        private static void AddFrameworks(PBXProject project, string targetGuid)
        {
            if (string.IsNullOrEmpty(targetGuid))
            {
                return;
            }

            project.AddFrameworkToProject(targetGuid, "PhotosUI.framework", false);
            project.AddFrameworkToProject(targetGuid, "Photos.framework", false);
        }
    }
}
