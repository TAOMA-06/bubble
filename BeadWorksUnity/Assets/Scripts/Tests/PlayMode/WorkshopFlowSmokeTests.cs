using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using BeadWorks.Core;
using BeadWorks.UI;
using BeadWorks.Workshop;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.TestTools;
using UnityEngine.UI;
#if UNITY_EDITOR
using UnityEditor.SceneManagement;
#endif

namespace BeadWorks.Tests.PlayMode
{
    /// <summary>
    /// End-to-end navigation smoke tests over the real WorkshopScene: both free-create
    /// sizes, the image import pipeline, and the ironing -> showcase -> gallery save loop.
    /// The photo picker's native/Editor UI can't be automated headlessly, so the import
    /// test drives the internal "photo picked" callback directly via reflection.
    /// </summary>
    public class WorkshopFlowSmokeTests
    {
        private const string ScenePath = "Assets/Scenes/WorkshopScene.unity";
        private readonly List<string> _unexpectedLogs = new();

        [UnitySetUp]
        public IEnumerator SetUp()
        {
            _unexpectedLogs.Clear();
            Application.logMessageReceived += OnLogMessageReceived;
#if UNITY_EDITOR
            EditorSceneManager.LoadSceneInPlayMode(ScenePath, new LoadSceneParameters(LoadSceneMode.Single));
#else
            SceneManager.LoadScene("WorkshopScene");
#endif
            yield return null;
            yield return null;
        }

        [UnityTearDown]
        public IEnumerator TearDown()
        {
            Application.logMessageReceived -= OnLogMessageReceived;
            Assert.IsEmpty(_unexpectedLogs, string.Join("\n", _unexpectedLogs));
            yield return null;
        }

        [UnityTest]
        public IEnumerator MainMenu_IsShownOnLaunch()
        {
            var appFlow = FindAppFlow();
            Assert.AreEqual(AppScreen.MainMenu, appFlow.CurrentScreen);

            var mainMenuPanel = GameObject.Find("MainMenuPanel");
            Assert.IsNotNull(mainMenuPanel, "MainMenuPanel was not created");
            Assert.IsTrue(mainMenuPanel.activeInHierarchy, "MainMenuPanel should be visible on launch");

            var workshop = GameObject.Find("Workshop");
            Assert.IsFalse(workshop != null && workshop.activeInHierarchy, "Workshop should be hidden behind the main menu");
            yield return null;
        }

        [UnityTest]
        public IEnumerator FreeCreate_StandardSize_ReachesWorkshop()
        {
            var appFlow = FindAppFlow();

            ClickButtonNamed("FreeCreate");
            yield return null;
            yield return null;

            Assert.AreEqual(AppScreen.Workshop, appFlow.CurrentScreen);

            var workshop = Object.FindFirstObjectByType<WorkshopController>();
            Assert.AreEqual(MainMenuUIController.StandardGridSize, workshop.GridSize);
        }

        [UnityTest]
        public IEnumerator FreeCreate_SimplifiedSize_ReachesWorkshop()
        {
            FindAppFlow();

            ClickButtonNamed("SizeChipSimplified");
            yield return null;
            ClickButtonNamed("FreeCreate");
            yield return null;
            yield return null;

            var appFlow = FindAppFlow();
            Assert.AreEqual(AppScreen.Workshop, appFlow.CurrentScreen);

            var workshop = Object.FindFirstObjectByType<WorkshopController>();
            Assert.AreEqual(MainMenuUIController.SimplifiedGridSize, workshop.GridSize);
        }

        [UnityTest]
        public IEnumerator ImageImport_ConfirmedPattern_ReachesWorkshopWithGuide()
        {
            var appFlow = FindAppFlow();

            ClickButtonNamed("ImageImport");
            yield return null;

            Assert.AreEqual(AppScreen.ImageImport, appFlow.CurrentScreen);

            var importUi = Object.FindFirstObjectByType<ImageImportUIController>();
            Assert.IsNotNull(importUi, "ImageImportUIController not found in scene");

            var texture = new Texture2D(8, 8, TextureFormat.RGBA32, false);
            var pixels = new Color[64];
            for (var i = 0; i < pixels.Length; i++)
            {
                pixels[i] = Color.red;
            }

            texture.SetPixels(pixels);
            texture.Apply();

            var onPhotoPicked = typeof(ImageImportUIController).GetMethod(
                "OnPhotoPicked", BindingFlags.NonPublic | BindingFlags.Instance);
            Assert.IsNotNull(onPhotoPicked, "OnPhotoPicked method not found via reflection");
            onPhotoPicked.Invoke(importUi, new object[] { texture });
            yield return null;

            ClickButtonNamed("Confirm");
            yield return null;
            yield return null;

            Assert.AreEqual(AppScreen.Workshop, appFlow.CurrentScreen);

            var workshop = Object.FindFirstObjectByType<WorkshopController>();
            Assert.IsNotNull(workshop.Session);
            Assert.AreEqual(PatternSource.Imported, workshop.Session.Source);
        }

        [UnityTest]
        public IEnumerator IroningToShowcaseToGallerySave_EndToEnd()
        {
            var appFlow = FindAppFlow();

            ClickButtonNamed("FreeCreate");
            yield return null;
            yield return null;
            Assert.AreEqual(AppScreen.Workshop, appFlow.CurrentScreen);

            var workshop = Object.FindFirstObjectByType<WorkshopController>();
            workshop.DebugSimulateIroningAndFinish();
            yield return null;

            ClickButtonNamed("ShowcaseButton");
            yield return null;
            yield return null;

            Assert.AreEqual(AppScreen.FinishedViewer, appFlow.CurrentScreen);

            var worksBefore = appFlow.Gallery.Works.Count;
            ClickButtonNamed("Save");
            yield return null;

            Assert.AreEqual(worksBefore + 1, appFlow.Gallery.Works.Count);

            ClickButtonNamed("Menu");
            yield return null;

            Assert.AreEqual(AppScreen.MainMenu, appFlow.CurrentScreen);
        }

        private static AppFlowController FindAppFlow()
        {
            var appFlow = Object.FindFirstObjectByType<AppFlowController>();
            Assert.IsNotNull(appFlow, "AppFlowController not found in scene");
            return appFlow;
        }

        private static void ClickButtonNamed(string name)
        {
            // Only currently active buttons: several screens reuse names like "Menu", and
            // only one screen's panel is active at a time, matching what a real tap could reach.
            var buttons = Object.FindObjectsByType<Button>(FindObjectsInactive.Exclude, FindObjectsSortMode.None);
            foreach (var button in buttons)
            {
                if (button.name == name)
                {
                    button.onClick.Invoke();
                    return;
                }
            }

            Assert.Fail($"Active button named '{name}' not found");
        }

        private void OnLogMessageReceived(string condition, string stackTrace, LogType type)
        {
            if (type != LogType.Exception && type != LogType.Error)
            {
                return;
            }

            if (condition.Contains("NullReferenceException") ||
                condition.Contains("MissingReferenceException") ||
                condition.Contains("Can't add component") ||
                condition.Contains("Cannot initialize BeadWorks UI"))
            {
                _unexpectedLogs.Add($"{type}: {condition}\n{stackTrace}");
            }
        }
    }
}
