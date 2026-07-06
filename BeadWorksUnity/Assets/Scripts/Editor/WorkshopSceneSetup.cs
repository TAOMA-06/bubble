using BeadWorks.Core;
using BeadWorks.Presentation;
using BeadWorks.UI;
using BeadWorks.Workshop;
using TMPro;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace BeadWorks.Editor
{
    public static class WorkshopSceneSetup
    {
        private const string ScenePath = "Assets/Scenes/WorkshopScene.unity";

        [MenuItem("BeadWorks/Setup Workshop Scene")]
        public static void SetupScene()
        {
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            scene.name = "WorkshopScene";

            var bootstrap = new GameObject("GameBootstrap");
            var workshop = bootstrap.AddComponent<WorkshopController>();
            var input = bootstrap.AddComponent<Input.InputController>();
            bootstrap.AddComponent<GameBootstrap>();
            bootstrap.AddComponent<BeadFactory>();
            bootstrap.AddComponent<Feedback.WorkshopFeedback>();

            var workshopRoot = new GameObject("Workshop");
            var workbench = workshopRoot.AddComponent<WorkbenchBackground>();
            var pegboardRoot = new GameObject("PegboardRoot");
            pegboardRoot.transform.SetParent(workshopRoot.transform, false);
            var pegboard = pegboardRoot.AddComponent<PegboardPresenter>();

            var cameraGo = new GameObject("Main Camera");
            cameraGo.tag = "MainCamera";
            var camera = cameraGo.AddComponent<Camera>();
            camera.orthographic = true;
            camera.orthographicSize = 6f;
            camera.backgroundColor = new Color(0.12f, 0.13f, 0.15f);
            cameraGo.AddComponent<AudioListener>();
            var cameraController = cameraGo.AddComponent<CameraController>();

            var lightGo = new GameObject("Directional Light");
            var light = lightGo.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.1f;
            lightGo.transform.rotation = Quaternion.Euler(50f, -30f, 0f);

            var eventSystem = new GameObject("EventSystem");
            eventSystem.AddComponent<EventSystem>();
            eventSystem.AddComponent<StandaloneInputModule>();

            var canvasGo = new GameObject("UI");
            var canvas = canvasGo.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasGo.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080, 1920);
            scaler.matchWidthOrHeight = 0.5f;
            canvasGo.AddComponent<GraphicRaycaster>();

            var palettePanel = CreatePanel(canvasGo.transform, "ColorPalettePanel",
                new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f),
                new Vector2(0, 140), new Vector2(980, 120));
            var paletteLayout = palettePanel.gameObject.AddComponent<HorizontalLayoutGroup>();
            paletteLayout.spacing = 12f;
            paletteLayout.childAlignment = TextAnchor.MiddleCenter;
            paletteLayout.childControlWidth = false;
            paletteLayout.childControlHeight = false;

            var toolbarPanel = CreatePanel(canvasGo.transform, "ToolbarPanel",
                new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f),
                new Vector2(0, 40), new Vector2(720, 96));
            var toolbarLayout = toolbarPanel.gameObject.AddComponent<HorizontalLayoutGroup>();
            toolbarLayout.spacing = 16f;
            toolbarLayout.childAlignment = TextAnchor.MiddleCenter;
            toolbarLayout.childControlWidth = false;
            toolbarLayout.childControlHeight = false;

            var statusGo = new GameObject("StatusText");
            statusGo.transform.SetParent(canvasGo.transform, false);
            var statusRect = statusGo.AddComponent<RectTransform>();
            statusRect.anchorMin = new Vector2(0.5f, 1f);
            statusRect.anchorMax = new Vector2(0.5f, 1f);
            statusRect.pivot = new Vector2(0.5f, 1f);
            statusRect.anchoredPosition = new Vector2(0, -24);
            statusRect.sizeDelta = new Vector2(900, 48);
            var statusText = statusGo.AddComponent<TextMeshProUGUI>();
            statusText.alignment = TextAlignmentOptions.Center;
            statusText.fontSize = 24;
            statusText.color = new Color(0.9f, 0.92f, 0.95f);
            statusText.text = "Workshop";

            var uiController = canvasGo.AddComponent<WorkshopUIController>();
            var ironingUiController = canvasGo.AddComponent<IroningUIController>();

            var swatchPrefab = AssetDatabase.LoadAssetAtPath<Button>("Assets/Prefabs/SwatchButton.prefab");
            var toolPrefab = AssetDatabase.LoadAssetAtPath<Button>("Assets/Prefabs/ToolButton.prefab");
            var paletteJson = AssetDatabase.LoadAssetAtPath<TextAsset>("Assets/Data/bead_palette.json");
            var pegboardMaterial = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/M_PegboardSurface.mat");
            var beadMaterial = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/M_Bead.mat");

            var bootstrapComponent = bootstrap.GetComponent<GameBootstrap>();
            var beadFactory = bootstrap.GetComponent<BeadFactory>();
            var feedback = bootstrap.GetComponent<Feedback.WorkshopFeedback>();
            var serializedBootstrap = new SerializedObject(bootstrapComponent);
            serializedBootstrap.FindProperty("_workshopController").objectReferenceValue = workshop;
            serializedBootstrap.FindProperty("_inputController").objectReferenceValue = input;
            serializedBootstrap.FindProperty("_cameraController").objectReferenceValue = cameraController;
            serializedBootstrap.FindProperty("_pegboardPresenter").objectReferenceValue = pegboard;
            serializedBootstrap.FindProperty("_workbenchBackground").objectReferenceValue = workbench;
            serializedBootstrap.FindProperty("_uiController").objectReferenceValue = uiController;
            serializedBootstrap.FindProperty("_ironingUIController").objectReferenceValue = ironingUiController;
            serializedBootstrap.FindProperty("_workshopRoot").objectReferenceValue = workshopRoot.transform;
            serializedBootstrap.FindProperty("_pegboardRoot").objectReferenceValue = pegboardRoot.transform;
            serializedBootstrap.FindProperty("_paletteJson").objectReferenceValue = paletteJson;
            serializedBootstrap.FindProperty("_beadFactory").objectReferenceValue = beadFactory;
            serializedBootstrap.FindProperty("_workshopFeedback").objectReferenceValue = feedback;
            serializedBootstrap.ApplyModifiedPropertiesWithoutUndo();

            var serializedUi = new SerializedObject(uiController);
            serializedUi.FindProperty("_paletteContainer").objectReferenceValue = palettePanel;
            serializedUi.FindProperty("_toolbarContainer").objectReferenceValue = toolbarPanel;
            serializedUi.FindProperty("_statusText").objectReferenceValue = statusText;
            serializedUi.FindProperty("_swatchButtonPrefab").objectReferenceValue = swatchPrefab;
            serializedUi.FindProperty("_toolButtonPrefab").objectReferenceValue = toolPrefab;
            serializedUi.ApplyModifiedPropertiesWithoutUndo();

            var serializedPegboard = new SerializedObject(pegboard);
            serializedPegboard.FindProperty("_holeMaterial").objectReferenceValue = pegboardMaterial;
            serializedPegboard.ApplyModifiedPropertiesWithoutUndo();

            var serializedBeadFactory = new SerializedObject(beadFactory);
            serializedBeadFactory.FindProperty("_beadMaterial").objectReferenceValue = beadMaterial;
            serializedBeadFactory.ApplyModifiedPropertiesWithoutUndo();

            var serializedWorkbench = new SerializedObject(workbench);
            serializedWorkbench.FindProperty("_surfaceMaterial").objectReferenceValue = pegboardMaterial;
            serializedWorkbench.ApplyModifiedPropertiesWithoutUndo();

            var serializedCamera = new SerializedObject(cameraController);
            serializedCamera.FindProperty("_pegboardTarget").objectReferenceValue = pegboardRoot.transform;
            serializedCamera.ApplyModifiedPropertiesWithoutUndo();

            EditorSceneManager.SaveScene(scene, ScenePath);
            AssetDatabase.SaveAssets();
            Debug.Log($"[BeadWorks] Workshop scene saved to {ScenePath}");
        }

        private static RectTransform CreatePanel(Transform parent, string name, Vector2 anchorMin, Vector2 anchorMax,
            Vector2 pivot, Vector2 anchoredPosition, Vector2 sizeDelta)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var rect = go.AddComponent<RectTransform>();
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.pivot = pivot;
            rect.anchoredPosition = anchoredPosition;
            rect.sizeDelta = sizeDelta;

            var image = go.AddComponent<Image>();
            image.color = new Color(0.1f, 0.11f, 0.13f, 0.55f);
            return rect;
        }
    }
}
