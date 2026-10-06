# Codex Prompt — SANRO Dev Toolkit V1.2.0 Validation on Superadmin

Gunakan prompt ini ketika Codex aktif kembali. Tujuannya adalah mempraktikkan SANRO Dev Toolkit V1.2.0 secara nyata pada SANRO Superadmin sebelum Codex kembali mengerjakan fitur.

## Prompt

LANJUTKAN SANRO SUPERADMIN DENGAN SANRO DEV TOOLKIT V1.2.0.

Repo toolkit:
`arioguswara-oss/Sanro-Dev-Toolkit`

Repo project:
`arioguswara-oss/Sanro-SuperAdmin`

Branch aktif project:
`codex/superadmin-v030-baseline-audit-20261004`

Tujuan pertama: lakukan smoke test nyata SANRO Dev Toolkit sebagai workflow Codex, BUKAN coding fitur dulu.

Ikuti urutan:

1. Sync repo `Sanro-Dev-Toolkit` ke `main` terbaru.
2. Sync repo `Sanro-SuperAdmin` ke branch aktif terbaru.
3. Baca `AGENTS.md` project.
4. Jalankan dari repo toolkit terhadap workspace Superadmin:

```powershell
.\sanro-dev.ps1 handoff -ProjectRoot "C:\Users\Ario\Documents\ChatGPT\Sanro-SuperAdmin-Work"
.\sanro-dev.ps1 status -ProjectRoot "C:\Users\Ario\Documents\ChatGPT\Sanro-SuperAdmin-Work"
.\sanro-dev.ps1 context -ProjectRoot "C:\Users\Ario\Documents\ChatGPT\Sanro-SuperAdmin-Work" -Query "subscription"
.\sanro-dev.ps1 check -ProjectRoot "C:\Users\Ario\Documents\ChatGPT\Sanro-SuperAdmin-Work"
.\sanro-dev.ps1 test -ProjectRoot "C:\Users\Ario\Documents\ChatGPT\Sanro-SuperAdmin-Work" -Filter "subscription"
```

5. Jangan full scan repo.
6. Jangan jalankan full regression kecuali focused smoke test selesai dan memang diperlukan.
7. Jangan ubah production, hosting, migration, credential, `.env`, atau route default-OFF.
8. Jangan rerun Migration 06.
9. Jangan jalankan Migration 07.
10. Jangan touch SANRO POS/Stock production.

Setelah smoke test, laporkan singkat:
- command mana PASS/FAIL;
- apakah `handoff` memberi context yang cukup untuk takeover setelah reset;
- apakah `context` mengurangi kebutuhan broad scan;
- bug/inefisiensi toolkit yang ditemukan;
- estimasi apakah workflow ini lebih hemat quota dibanding bootstrap lama.

Jika semua PASS, tandai toolkit sebagai:
`CODEX PRACTICED / VALIDATED`

Setelah itu, bila quota masih cukup, lanjutkan highest-priority safe non-blocked lane sesuai `docs/SUPERADMIN_WORKBOARD.md`, dengan workflow:
`handoff/status -> sync -> relevant context -> scoped work -> check -> focused test -> commit -> full regression near batch end -> handoff`

GitHub remote HEAD tetap source of truth. Jangan recreate/revert pekerjaan ChatGPT yang lebih baru.

## Short prompt after first successful validation

Setelah validasi pertama sudah PASS, Rio cukup mengirim:

`Codex, lanjut pakai SANRO Dev Toolkit. Sync remote HEAD, jalankan handoff/status, baca AGENTS + workboard/checkpoint relevan, lalu ambil highest-priority safe non-conflicting lane. Focused test dulu, full regression hanya di akhir coherent batch.`
