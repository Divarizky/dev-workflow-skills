# Dev Workflow Skills

Kumpulan Agent Skills untuk membantu solo developer bekerja lebih terstruktur:
mulai dari requirement, task breakdown, implementasi, debugging, review,
commit, sampai handoff antar-sesi.

## Mulai dalam 3 langkah

### 1. Install

Windows:

```powershell
git clone https://github.com/Divarizky/dev-workflow-skills.git
cd dev-workflow-skills
.\install.ps1 --Pi
```

macOS/Linux:

```bash
git clone https://github.com/Divarizky/dev-workflow-skills.git
cd dev-workflow-skills
./install.sh --Pi
```

Git dan salah satu agent berikut diperlukan:

- [Pi](https://github.com/badlogic/pi-mono)
- Codex
- Claude Code

### 2. Buka project

Jalankan agent dari root project yang ingin dikerjakan.

### 3. Jelaskan pekerjaan

Tidak tahu harus memakai skill apa? Cukup tulis:

```text
Saya mau menambahkan sistem billing ke project ini. Bantu saya mulai.
```

`ask-me` akan membantu mengklarifikasi kebutuhan dan memilih alur.

Kalau sudah tahu skill yang dibutuhkan, sebutkan langsung:

```text
Gunakan to-requirements untuk merumuskan fitur billing ini.
```

## Flow keseluruhan

```mermaid
flowchart TD
    classDef gate fill:#f97316,stroke:#c2410c,stroke-width:2px,color:#fff;
    classDef review fill:#8b5cf6,stroke:#6d28d9,stroke-width:2px,color:#fff;
    classDef build fill:#0284c7,stroke:#0369a1,stroke-width:2px,color:#fff;
    classDef context fill:#059669,stroke:#047857,stroke-width:2px,color:#fff;

    USER([Prompt / Request]) --> ENTRY{Tahu skill yang dipakai?}
    ENTRY -->|Tidak / Ambigu| ASK[ask-me<br/><i>Klarifikasi & Routing</i>]:::gate
    ENTRY -->|Ya| DIRECT[Skill Langsung]:::gate

    ASK --> MODE{Perlu Project mode?}
    DIRECT --> MODE

    MODE -->|Tidak| UNIVERSAL[Universal Mode<br/><i>Chat-only, cepat</i>]
    MODE -->|Ya| SETUP[setup-workflow<br/><i>AGENTS + Context + SRS</i>]:::context
    SETUP --> PROJECT[Project Mode Aktif]:::context
    UNIVERSAL --> ROUTE{Jenis Pekerjaan}
    PROJECT --> ROUTE

    %% 7 Cabang
    ROUTE -->|Fitur Besar| REQ[to-requirements]:::build
    REQ --> TASK[to-tasks]:::build
    TASK --> IMP[implement]:::build

    ROUTE -->|Fitur Kecil| IMP
    ROUTE -->|Bug Sulit| BUG[bug-diagnosis]:::build
    ROUTE -->|Desain Ragu| PROTO[prototype]:::build
    PROTO --> IMP

    ROUTE -->|Arsitektur / Debt| ARCH[improve-architecture]:::build
    ARCH --> IMP

    ROUTE -->|Konflik Git| CONF[merge-conflict]:::gate
    CONF --> COMMIT[git-commit]:::gate

    ROUTE -->|Migrasi Codebase| MIG[project-migration]:::context
    MIG --> IMP

    %% Delivery Gate
    IMP --> REV[code-review]:::review
    BUG --> REV
    REV -->|REVISE| IMP
    REV -->|PASS| COMMIT
    COMMIT --> DONE([Selesai / Clean State]):::gate
```

---

### 1. Feature Lifecycle Flow (Fitur Besar & Fast-Track)

Alur pengembangan fitur terstruktur dari perumusan spesifikasi (EARS), breakdown task, siklus TDD red-green-refactor, hingga dual-axis review dan commit gate dengan reuse snapshot.

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Developer
    participant Ask as ask-me
    participant Req as to-requirements
    participant Task as to-tasks
    participant Imp as implement
    participant Rev as code-review
    participant Git as git-commit

    Dev->>Ask: Request fitur baru
    Ask->>Ask: Grill (3-5 pertanyaan klarifikasi)
    Ask->>Req: Handoff fitur besar
    Req->>Req: Formulasi EARS + work card F-<id>.md
    Req->>Dev: Gate [1] Approve [2] Approve+to-tasks [3] Revisi
    Dev->>Task: Opsi [2] Lanjut breakdown
    Task->>Task: Generate TASK-xx + update TRACKER.md
    Task->>Imp: Kirim paket chain inline
    loop TDD Cycle
        Imp->>Imp: Red -> Green -> Refactor
    end
    Imp->>Rev: Kirim staged diff + Ref/Done criteria
    Rev->>Rev: 3 Sub-Agents (Spec, Standards, Safety)
    Rev-->>Imp: Verdict: PASS (simpan Reviewed Snapshot)
    Imp->>Git: Chain ke commit (Index final)
    Git->>Git: Bypass review ulang (Reuse PASS snapshot) + Scan Gitleaks
    Git->>Dev: Commit tersimpan bersih
```

---

### 2. Investigation, Spiking & Architecture Flow

Alur investigasi akar masalah (RCA) 6 fase, eksplorasi desain/spike yang belum pasti via prototype, dan audit technical debt/coupling berkala.

```mermaid
flowchart LR
    classDef diag fill:#ea580c,stroke:#c2410c,stroke-width:2px,color:#fff;
    classDef fix fill:#0284c7,stroke:#0369a1,stroke-width:2px,color:#fff;
    classDef gate fill:#8b5cf6,stroke:#6d28d9,stroke-width:2px,color:#fff;

    ERR([Error / Crash]) --> BUG[bug-diagnosis<br/><i>Vertical Repro Harness</i>]:::diag
    BUG --> ROOT{Diagnosis Only?}
    ROOT -->|Ya| REPORT[Laporan RCA + Rekomendasi Solusi]:::diag
    ROOT -->|Tidak| FIX[Targeted Fix Implementation]:::fix
    
    DEBT([Technical Debt]) --> ARCH[improve-architecture<br/><i>Scan Coupling & Layer</i>]:::diag
    ARCH --> FIX

    SPIKE([Desain Ragu]) --> PROTO[prototype<br/><i>Spike LOGIC / UI</i>]:::diag
    PROTO --> FIX

    FIX --> REV[code-review<br/><i>Spec + Style + Security</i>]:::gate
    REV --> GIT[git-commit<br/><i>Gitleaks Gate</i>]:::gate
```

---

### 3. Migration & Git Conflict Resolution Flow

Alur migrasi struktur codebase secara bertahap via state di `.workspace/migration/`, serta resolusi konflik Git hunk-by-hunk dengan verifikasi tes sebelum commit.

```mermaid
flowchart LR
    classDef setup fill:#059669,stroke:#047857,stroke-width:2px,color:#fff;
    classDef git fill:#d97706,stroke:#b45309,stroke-width:2px,color:#fff;
    classDef gate fill:#8b5cf6,stroke:#6d28d9,stroke-width:2px,color:#fff;

    MIG_REQ([Migrasi Stack / Codebase]) --> SETUP[setup-workflow<br/><i>Init AGENTS + Context</i>]:::setup
    SETUP --> MIG[project-migration<br/><i>State di .workspace/migration</i>]:::setup
    MIG --> VERIFY[Build & Test Verification]:::gate

    CONF_REQ([Merge / Rebase Conflict]) --> CONF[merge-conflict<br/><i>Guided Hunk Resolution</i>]:::git
    CONF --> VERIFY

    VERIFY --> GIT[git-commit<br/><i>Verified Tree Commit</i>]:::gate
```

## Kapan memakai setiap skill?

| Skill | Gunakan untuk | Contoh prompt |
|---|---|---|
| `ask-me` | Klarifikasi dan routing | `Bantu saya menentukan langkah untuk fitur ini.` |
| `to-requirements` | Requirement dan acceptance criteria | `Buat requirements untuk fitur billing.` |
| `to-tasks` | Memecah requirement menjadi task | `Pecah requirements ini menjadi task.` |
| `implement` | Mengerjakan task | `Implementasikan task export CSV ini.` |
| `bug-diagnosis` | Bug yang sulit direproduksi | `Cari penyebab timeout ini dengan bug-diagnosis.` |
| `prototype` | Mengeksplorasi desain atau behavior | `Bandingkan dua desain API ini.` |
| `improve-architecture` | Analisis arsitektur dan refactor | `Cari peluang perbaikan arsitektur.` |
| `code-review` | Review perubahan | `Review perubahan staged ini.` |
| `git-commit` | Membuat commit | `Siapkan commit dari perubahan ini.` |
| `merge-conflict` | Konflik merge/rebase/cherry-pick | `Bantu resolve conflict yang aktif.` |
| `setup-workflow` | Gate Project mode, context, dan tracking project | `Siapkan workflow untuk project ini.` |
| `project-migration` | Migrasi project lama | `Migrasikan project lama ini.` |
| `status` | Snapshot pekerjaan | `Saya sedang mengerjakan apa?` |
| `handoff` | Melanjutkan di sesi lain | `Buat handoff untuk besok.` |

## Dua mode kerja

- **Universal mode**: default, tanpa `.workspace`, cocok untuk pekerjaan satu sesi.
  Hasil workflow ditampilkan di chat.
- **Project mode**: aktif jika `.workspace/project-meta.md` tersedia. Context,
  requirements, task, tracker, dan handoff disimpan di `.workspace/`.

`setup-workflow` adalah **gate umum** untuk project yang membutuhkan Project
mode, context, atau dokumentasi yang jelas. Setelah setup selesai, lanjutkan ke
skill sesuai kebutuhan project; tidak harus migrasi.

```text
Jalankan setup-workflow untuk project ini.
```

Salah satu cabangnya adalah migrasi:

```text
setup-workflow → project-migration
```

`project-migration` wajib menggunakan Project mode.

## Aturan penting

- Skill selain `ask-me` umumnya dipanggil langsung atau dijalankan sebagai chain.
- `code-review` dilakukan sebelum commit.
- Commit, resolusi conflict, migration cleanup, dan aksi berisiko memerlukan
  konfirmasi sesuai kondisinya.
- `bug-diagnosis` dapat berhenti sebagai diagnosis-only jika belum diminta
  memperbaiki bug.
- `prototype` menghasilkan keputusan desain; tidak mengubah production code
  kecuali prototype executable diminta secara eksplisit.

## Advanced installation and maintenance

Gunakan bagian ini hanya jika diperlukan.

| Flag | Fungsi |
|---|---|
| `--Pi` | Pasang untuk Pi |
| `--Codex` | Pasang untuk Codex |
| `--Claude` | Pasang untuk Claude Code |
| `--backup-existing` | Backup target lama sebelum membuat link |
| `--unlink` | Melepas link yang dibuat installer |
| `--repo-url URL` | Menggunakan repository source lain |

Contoh memasang ke beberapa agent:

```powershell
.\install.ps1 --Pi --Codex --Claude
```

```bash
./install.sh --Pi --Codex --Claude
```

Untuk update, jalankan installer lagi. Jika clone default melalui SSH gagal,
gunakan `--repo-url` dengan URL HTTPS:

```powershell
.\install.ps1 --Pi --repo-url "https://github.com/Divarizky/dev-workflow-skills.git"
```

`--unlink` hanya melepas link; source skill tidak dihapus.

## Instalasi package Pi

```bash
pi install git:git@github.com:Divarizky/dev-workflow-skills
```

Untuk Codex dan Claude Code, gunakan installer di atas.

## Dokumentasi lengkap

- [Workflow utama](skills/dev/WORKFLOW.md)
- [Aturan umum](skills/dev/shared/COMMON.md)
- [Prompt design dan safety](skills/dev/shared/PROMPT-DESIGN.md)

## Kontribusi

Baca dokumentasi lengkap sebelum mengubah skill. Sertakan contoh penggunaan dan
cara validasi pada setiap perubahan.
