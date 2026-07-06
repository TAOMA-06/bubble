using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEngine;

namespace BeadWorks.Data
{
    /// <summary>
    /// Persists finished works to Application.persistentDataPath/gallery.
    /// </summary>
    public class GalleryRepository
    {
        private const string IndexFileName = "index.json";
        private readonly string _rootPath;
        private GalleryIndex _index = new();

        public IReadOnlyList<FinishedWorkRecord> Works => _index.works;

        public GalleryRepository()
        {
            _rootPath = Path.Combine(Application.persistentDataPath, "gallery");
            Directory.CreateDirectory(_rootPath);
            Load();
        }

        public void Load()
        {
            var indexPath = Path.Combine(_rootPath, IndexFileName);
            if (!File.Exists(indexPath))
            {
                _index = new GalleryIndex();
                return;
            }

            try
            {
                var json = File.ReadAllText(indexPath);
                _index = JsonUtility.FromJson<GalleryIndex>(json) ?? new GalleryIndex();
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"[GalleryRepository] Failed to load index: {ex.Message}");
                _index = new GalleryIndex();
            }
        }

        public void SaveWork(FinishedWorkRecord record, byte[] thumbnailPng = null)
        {
            if (string.IsNullOrEmpty(record.id))
            {
                record.id = Guid.NewGuid().ToString("N");
            }

            if (thumbnailPng != null && thumbnailPng.Length > 0)
            {
                record.thumbnailFileName = $"{record.id}.png";
                var thumbPath = Path.Combine(_rootPath, record.thumbnailFileName);
                File.WriteAllBytes(thumbPath, thumbnailPng);
            }

            var list = _index.works?.ToList() ?? new List<FinishedWorkRecord>();
            list.RemoveAll(w => w.id == record.id);
            list.Insert(0, record);
            _index.works = list.ToArray();
            WriteIndex();
        }

        public FinishedWorkRecord GetById(string id)
        {
            return _index.works?.FirstOrDefault(w => w.id == id);
        }

        public string GetThumbnailPath(FinishedWorkRecord record)
        {
            if (record == null || string.IsNullOrEmpty(record.thumbnailFileName))
            {
                return null;
            }

            return Path.Combine(_rootPath, record.thumbnailFileName);
        }

        public void Delete(string id)
        {
            var record = GetById(id);
            if (record == null)
            {
                return;
            }

            if (!string.IsNullOrEmpty(record.thumbnailFileName))
            {
                var thumbPath = Path.Combine(_rootPath, record.thumbnailFileName);
                if (File.Exists(thumbPath))
                {
                    File.Delete(thumbPath);
                }
            }

            _index.works = _index.works.Where(w => w.id != id).ToArray();
            WriteIndex();
        }

        private void WriteIndex()
        {
            var indexPath = Path.Combine(_rootPath, IndexFileName);
            var json = JsonUtility.ToJson(_index, true);
            File.WriteAllText(indexPath, json);
        }
    }
}
