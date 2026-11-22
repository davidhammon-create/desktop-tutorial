import React, { useRef, useState } from 'react';
import { UploadedFile } from '@/types/business';
import { T, sans } from '@/components/lexara/theme';
import { Panel, Label } from '@/components/lexara/Primitives';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
const ALLOWED_TYPES = [
  'application/pdf',
  'image/jpeg', 'image/png', 'image/webp', 'image/jpg',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.ms-excel',
  'text/csv', 'application/csv', 'text/plain',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/msword',
  'application/json',
  'application/xml', 'text/xml',
];
const ALLOWED_EXTENSIONS = [
  'pdf', 'jpg', 'jpeg', 'png', 'webp',
  'xlsx', 'xls', 'csv', 'docx', 'doc',
  'txt', 'json', 'xml',
];
const FILE_ICONS: Record<string, string> = {
  'application/pdf': '?',
  'image/jpeg': '??', 'image/png': '??', 'image/webp': '??', 'image/jpg': '??',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': '?',
  'application/vnd.ms-excel': '?',
  'text/csv': '?', 'application/csv': '?',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': '?',
  'application/msword': '?',
  'text/plain': '?',
  'application/json': '?',
  'application/xml': '?', 'text/xml': '?',
};
function isAllowedFile(file: File) {
  const extension = file.name.split('.').pop()?.toLowerCase() || '';
  return ALLOWED_TYPES.includes(file.type) || ALLOWED_EXTENSIONS.includes(extension);
}
function formatSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}
interface Props {
  files: UploadedFile[];
  scenarioId: string;
  onFilesChange: (files: UploadedFile[]) => void;
}
export function FileUploadSection({ files, scenarioId, onFilesChange }: Props) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [dragOver, setDragOver] = useState(false);
  const uploadFiles = async (fileList: FileList | File[]) => {
    const { data: { user } } = await supabase.auth.getUser();
    const userId = user?.id || 'anonymous';
    const toUpload = Array.from(fileList).filter(f => {
      if (!isAllowedFile(f)) {
        toast.error(`${f.name}: Dateityp nicht unterstützt`);
        return false;
      }
      if (f.size > 20 * 1024 * 1024) {
        toast.error(`${f.name}: Datei zu groß (max 20 MB)`);
        return false;
      }
      return true;
    });
    if (!toUpload.length) return;
    setUploading(true);
    const newFiles: UploadedFile[] = [];
    for (const file of toUpload) {
      const fileId = crypto.randomUUID();
      const ext = file.name.split('.').pop() || '';
      const storagePath = `${userId}/${scenarioId}/${fileId}.${ext}`;
      const { error } = await supabase.storage
        .from('business-files')
        .upload(storagePath, file, { contentType: file.type });
      if (error) {
        console.error('Upload error:', error);
        toast.error(`Fehler beim Hochladen von ${file.name}`);
        continue;
      }
      newFiles.push({
        id: fileId,
        name: file.name,
        size: file.size,
        type: file.type,
        storagePath,
        uploadedAt: new Date().toISOString(),
      });
    }
    if (newFiles.length) {
      onFilesChange([...files, ...newFiles]);
      toast.success(`${newFiles.length} Datei(en) hochgeladen`);
    }
    setUploading(false);
  };
  const handleDelete = async (file: UploadedFile) => {
    const { error } = await supabase.storage
      .from('business-files')
      .remove([file.storagePath]);
    if (error) {
      toast.error('Fehler beim Löschen');
      return;
    }
    onFilesChange(files.filter(f => f.id !== file.id));
    toast.success(`${file.name} gelöscht`);
  };
  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    if (e.dataTransfer.files.length) uploadFiles(e.dataTransfer.files);
  };
  return (
    <div style={{ marginBottom: 20 }}>
      <Label>? Dateien hochladen (Buchhaltung, Verträge, Dokumente?)</Label>
      {/* Drop zone */}
      <div
        onDragOver={e => { e.preventDefault(); setDragOver(true); }}
        onDragLeave={() => setDragOver(false)}
        onDrop={handleDrop}
        onClick={() => inputRef.current?.click()}
        style={{
          border: `2px dashed ${dragOver ? 'hsl(var(--primary))' : 'hsl(var(--border))'}`,
          borderRadius: 12,
          padding: '24px 16px',
          textAlign: 'center',
          cursor: 'pointer',
          background: dragOver ? 'hsl(var(--primary) / 0.05)' : 'hsl(var(--muted) / 0.3)',
          transition: 'all 0.2s',
          marginBottom: 12,
        }}
      >
        <div style={{ fontSize: 28, marginBottom: 6 }}>
          {uploading ? '?' : '?'}
        </div>
        <div style={{ fontSize: 13, color: T.dim, fontFamily: sans }}>
          {uploading
            ? 'Dateien werden hochgeladen?'
            : 'Dateien hierher ziehen oder klicken zum Auswählen'}
        </div>
        <div style={{ fontSize: 11, color: T.dim, marginTop: 4 }}>
          PDF, Excel, CSV, Word, Bilder, JSON, XML ? max. 20 MB
        </div>
      </div>
      <input
        ref={inputRef}
        type="file"
        multiple
        accept={ALLOWED_EXTENSIONS.map(ext => `.${ext}`).join(',')}
        style={{ display: 'none' }}
        onChange={e => {
          if (e.target.files?.length) uploadFiles(e.target.files);
          e.target.value = '';
        }}
      />
      {/* File list */}
      {files.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {files.map(file => (
            <div key={file.id} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '8px 12px', borderRadius: 8,
              background: 'hsl(var(--muted) / 0.4)',
              fontSize: 13, fontFamily: sans,
            }}>
              <span style={{ fontSize: 18 }}>{FILE_ICONS[file.type] || '?'}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{
                  fontWeight: 600, color: T.text,
                  overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                }}>{file.name}</div>
                <div style={{ fontSize: 11, color: T.dim }}>{formatSize(file.size)}</div>
              </div>
              <button
                onClick={() => handleDelete(file)}
                style={{
                  background: 'none', border: 'none', cursor: 'pointer',
                  fontSize: 16, color: T.dim, padding: 4,
                }}
                title="Löschen"
              >?</button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
