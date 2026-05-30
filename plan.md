<context>
## Project: FPGA Image Preprocessing Core for Alzheimer MRI Classification

### Hardware Design (locked decisions)
- Runtime-configurable generic 5×5 RGB convolution streaming core
- Kernels verified (0 mismatch, 2,061,616 valid outputs): Identity, Gaussian, Sharpen, Emboss, Laplacian
- Sobel: lõi hỗ trợ Sobel-X 5×5 và Sobel-Y 5×5 runtime-loadable; magnitude computed downstream
- Kernel load protocol: coeff_q shadow register, update when valid_in=0 only
- CPU benchmark: OpenCV GaussianBlur Ryzen 7 5800H: 1018 Mpix/s (16T), 303 Mpix/s (1T)
- FPGA không claim thắng desktop CPU — claim đúng là streaming hardware deterministic latency + embedded efficiency

### Paper positioning (locked)
- Title direction: "Runtime-Configurable FPGA Preprocessing Accelerator for Downstream Alzheimer MRI Classification"
- NOT claiming: FPGA replaces CNN, Sobel improves accuracy, FPGA faster than Ryzen
- IS claiming: hardware streaming preprocessing core + runtime kernel config + downstream evaluation
- Baseline so sánh: ARM Cortex-A embedded (Raspberry Pi / Zynq PS), NOT desktop CPU
- Novel point 1: Addressless SRL-based window generator (Design B) eliminates x_count→memory timing path
- Novel point 2: Shadow coefficient register (coeff_q) for timing-stable runtime kernel swap
- Novel point 3: Generic 5×5 uniform throughput regardless of kernel separability
- Novel point 4: Application-level evaluation: FPGA preprocessing modes → downstream Alzheimer classifier

### Application layer (to be designed)
- Dataset: Alzheimer MRI 2D (OASIS or Kaggle 4-class: NonDemented/VeryMild/Mild/Moderate)
- Downstream model: ResNet18 or ResNet50, runs on PC/GPU, weights fixed during evaluation
- Preprocessing branches to evaluate: Raw, Gaussian, Sharpen, Laplacian, Sobel-X, Sobel-Y, Sobel-magnitude, Unsharp Mask
- Sobel pipeline: 2-pass (Sobel-X then Sobel-Y via FPGA) → software magnitude |Gx|+|Gy| → feed CNN
- Goal: measure which preprocessing mode preserves/degrades discriminative MRI features
- Metric: Accuracy, F1-score, Precision, Recall per preprocessing branch

### What is NOT done yet (open tasks)
- Post-route Design B at 200 MHz (critical)
- Power measurement / Vivado Power Analysis for GOPS/W
- Sobel magnitude pipeline implementation and test
- Raspberry Pi / ARM baseline benchmark
- CNN downstream evaluation (accuracy per kernel)
- Paper writing

### Constraints
- MUST NOT claim: "preprocessing improves Alzheimer detection accuracy" as a given
- MUST frame accuracy results as evaluation/measurement, not as improvement claim
- MUST include post-route numbers before claiming 200 MHz officially
- Sobel MUST be called "Sobel-like 5×5 gradient operator" or "extended Sobel" not plain "Sobel 3×3"
các bài minh chứng sobel 5x5 tốt hơn 3x3 cho MRI alzheimer:
Luận điểm 1: Sobel preprocessing cải thiện CNN trên medical image
[P1] — Tang et al., PeerJ Computer Science, 2023
"Diagnostic efficiency of multi-modal MRI deep learning with Sobel operator" — dùng Sobel operator kết hợp CNN multi-modal để phân loại breast MRI benign/malignant, đây là paper trực tiếp nhất chứng minh Sobel + deep learning + MRI hoạt động tốt.
→ DOI: 10.7717/peerj-cs.1460 nih
[P2] — IEEE Xplore 2020 (Facial Expression)
"Facial Expression Recognition Based on Sobel Operator and Improved CNN-SVM" — thêm Sobel edge detection vào preprocessing stage trước CNN cải thiện accuracy +3.71% trên CK+ dataset.
→ IEEE Xplore, DOI: 10.1109/9232063 IEEE Xplore
[P3] — Sensors 2023
"Multi-Attention Segmentation Networks Combined with the Sobel Operator for Medical Images" — Sobel operator được tích hợp vào deep learning pipeline cho medical image segmentation, cải thiện khả năng focus vào key region.
→ DOI: 10.3390/s23052546 MDPI
 Luận điểm 2: Extended/multi-direction Sobel tốt hơn 3×3 chuẩn cho brain MRI
[P4] — Remya Ajai & Gopalan, Procedia Computer Science, 2022 ⭐ Paper quan trọng nhất
"Comparative Analysis of Eight Direction Sobel Edge Detection Algorithm for Brain Tumor MRI Images" — Sobel 8 hướng detect được tumor shape bất quy tắc trong brain MRI tốt hơn các edge detection algorithm truyền thống.
→ Procedia Computer Science Vol. 201, pp. 487–494, 2022 ResearchGate
[P5] — Chang et al., Journal of Parallel and Distributed Computing, 2023
"Multi-directional Sobel operator kernel on GPUs" — khẳng định rõ: "5×5 Sobel operator có edge detection robustness tương đương 7×7 nhưng cao hơn 3×3", đặc biệt với multi-directional application.
→ DOI: 10.1016/j.jpdc.2023.03.004 arxiv
[P6] — Image Segmentation for Mammographic Images (ResearchGate)
"Image Segmentation using Extended Edge Operator for Mammographic Images" — để đạt segmentation tốt hơn, 3×3 kernel được mở rộng lên 5×5 kernel thể hiện linear region rõ ràng hơn, phù hợp với medical image có cấu trúc thưa. ResearchGate

Luận điểm 3: Cortical boundary là key feature của Alzheimer
[P7] — AlSaeed & Omar, Sensors, 2022
"Brain MRI Analysis for Alzheimer's Disease Diagnosis Using CNN" — dùng FreeSurfer để extract 68 features của cortical thickness làm input chính cho model, xác nhận boundary/gradient feature là discriminative nhất cho Alzheimer.
→ DOI: 10.3390/s22082911 PubMed Central
[P8] — Novel CNN Architecture, Scientific Reports, 2024
"A novel CNN architecture for accurate early detection of Alzheimer's disease" — xác nhận feature quan trọng nhất trong Alzheimer MRI là grey/white matter volumes, cortical thickness, và CSF levels — tất cả đều là boundary feature.
→ DOI: 10.1038/s41598-024-53733-6 Nature
Luận điểm 4: Preprocessing cải thiện Alzheimer classification
[P9] — arXiv 2023
"Improvement in Alzheimer's Disease MRI Images via Topological Optimization" — áp dụng boundary enhancement, contrast và brightness adjustment trước CNN (VGG16, ResNet50, InceptionV3, Xception) làm accuracy tăng từ 74.25% → 88.66% (+14%).
→ arXiv:2310.16857 arxiv
[P10] — Bilateral filtering paper, PMC 2024
"A bilateral filtering-based image enhancement for Alzheimer disease classification using CNN" — noise trong MRI ảnh hưởng trực tiếp đến CNN accuracy; preprocessing giảm noise và tăng brightness cải thiện classification performance rõ rệt. nih
</context>
Luận điểm cần prove          Paper cite
─────────────────────────────────────────────
Sobel + CNN cải thiện        [P1] Tang 2023
accuracy trên MRI            [P2] IEEE 2020

Extended Sobel tốt hơn       [P4] Remya 2022  ← quan trọng nhất
3×3 cho brain MRI            [P5] Chang 2023
                             [P6] Mammographic

Cortical boundary =          [P7] AlSaeed 2022
key Alzheimer feature        [P8] Scientific Reports 2024

Preprocessing → accuracy     [P9] arXiv 2023
tăng với Alzheimer CNN       [P10] PMC 2024
<task>
Generate a complete, prioritized research and paper execution plan for this FPGA + Alzheimer preprocessing paper. 

The plan MUST:
1. Order all remaining tasks by dependency (what blocks what)
2. Separate into phases: Hardware Validation → Software/CNN Evaluation → Paper Writing
3. For each task specify: what to do, what output it produces, and what it unblocks
4. Flag the single highest-risk item that could break the paper if skipped
5. Suggest the minimum viable paper path if time is limited (fast track)
6. Include specific kernel values for Sobel-X 5×5 and Sobel-Y 5×5 that fit the Q8.8 fixed-point coefficient format of the FPGA core

Output format:
- Phase headers
- Numbered tasks under each phase
- Fast-track path clearly marked
- Risk flag clearly marked
- Kernel coefficient tables for Sobel 5×5 in Q8.8 format
- Language: Vietnamese for explanations, English for technical terms and kernel values
</task>

## Completed execution plan

### Verdict: lõi hiện tại có phù hợp để phát triển lên không?

Có. Lõi hiện tại phù hợp để phát triển thành một FPGA preprocessing accelerator cho Alzheimer MRI classification vì các điểm mạnh chính đã đúng hướng:

- Runtime-configurable arbitrary 5x5 kernel, phù hợp cho nhiều preprocessing modes mà không đổi RTL.
- Streaming one-pixel-per-clock, deterministic latency, hợp với edge/embedded preprocessing hơn là batch CPU.
- Đã có validation Full-HD cho nhiều kernel: identity, Gaussian, sharpen, emboss, Laplacian.
- Design B có novelty rõ hơn: addressless SRL-based window generator và coefficient-stationary runtime kernel.

Điều kiện bắt buộc khi phát triển tiếp:

- Không claim FPGA thay CNN.
- Không claim preprocessing chắc chắn cải thiện Alzheimer accuracy trước khi đo.
- Không claim 200 MHz chính thức nếu chưa có post-route timing closure.
- Với Sobel magnitude, phải xử lý vấn đề signed gradient vì output hiện tại saturate âm về 0.

---

## Phase 1 - Hardware Validation

### 1. Freeze hardware claim baseline

What to do:

- Chốt hai nhánh kết quả phần cứng:
  - Baseline A: post-route 146 MHz đã có.
  - Design B: SRL line buffer + coeff_q, hiện có post-synthesis 200 MHz.
- Ghi rõ Design B vẫn giữ 6-stage MAC pipeline.

Output:

- Một bảng hardware summary: frequency, timing stage, LUT, FF, BRAM, DSP, throughput.

Unblocks:

- Paper result section.
- Quyết định claim chính là 146 MHz post-route hay 200 MHz nếu route pass.

### 2. Run post-route Design B frequency sweep

What to do:

- Chạy implementation/post-route cho Design B ở các mốc:
  - 200 MHz
  - 190 MHz
  - 180 MHz
  - 170 MHz
  - 160 MHz nếu cần fallback
- Dùng cùng top `top_convolution`, part `xc7a100tcsg324-1`, `IMAGE_WIDTH=1920`.
- Giữ constraint coefficient-stationary hợp lệ: kernel chỉ update khi `valid_in=0`.

Output:

- `timing_post_route.rpt`
- `util_post_route.rpt`
- Fmax table với WNS/WHS.

Unblocks:

- Claim tần số chính thức.
- Hardware comparison table.
- Power analysis sau route.

### 3. Validate RTL regression after Design B

What to do:

- Chạy lại regression cho:
  - `identity5`
  - `gaussian5`
  - `sharpen5`
  - `laplacian5`
  - `emboss5`
  - `sobel_x5`
  - `sobel_y5`
- So sánh với Python golden model.

Output:

- PASS/FAIL table.
- Mismatch count.
- Valid output count.

Unblocks:

- Correctness claim.
- Paper verification section.

### 4. Add Sobel-like 5x5 kernel cases

What to do:

- Thêm Sobel-X 5x5 và Sobel-Y 5x5 vào Python golden model/test scripts.
- Gọi là `Sobel-like 5x5 gradient operator` hoặc `extended Sobel`, không gọi là Sobel 3x3.
- Dùng kernel Q8.8 ở cuối plan này.

Output:

- `sobel_x5` and `sobel_y5` test cases.
- Example output images for MRI/normal image.

Unblocks:

- Application preprocessing branch.
- CNN evaluation branch for edge/gradient inputs.

### 5. Resolve signed-gradient/magnitude protocol

What to do:

- Kiểm tra lại pipeline hiện tại: MAC result sau `>>> 8` bị saturate về RGB888, giá trị âm bị clamp về 0.
- Chọn một trong hai hướng:
  - No RTL change: chạy 4 passes `+Gx`, `-Gx`, `+Gy`, `-Gy`; software lấy `abs(Gx)=max(+Gx,-Gx)`, `abs(Gy)=max(+Gy,-Gy)`.
  - Small RTL option: thêm optional signed/bias/abs output mode ở stage pack, rồi chạy 2 passes `Gx`, `Gy`.

Output:

- Sobel magnitude method đã được document.
- Golden model matching.
- Một ảnh `sobel_magnitude`.

Unblocks:

- Downstream CNN Sobel-magnitude branch.
- Tránh lỗi claim sai về `|Gx|+|Gy|`.

### 6. Measure power with useful activity

What to do:

- Generate SAIF/VCD từ realistic frame stream.
- Chạy Vivado Power Analysis cho post-route design.
- Report:
  - static power
  - dynamic power
  - total power
  - activity coverage
  - throughput per watt

Output:

- `power_post_route_saif.rpt`
- GOPS/W hoặc Mpix/s/W.

Unblocks:

- Hardware efficiency comparison.
- ARM/Raspberry Pi comparison.

### 7. Run ARM/Raspberry Pi embedded baseline

What to do:

- Chạy cùng benchmark trên Raspberry Pi hoặc ARM Cortex-A/Zynq PS:
  - naive C 5x5, single thread
  - OpenCV `filter2D`, single thread
  - OpenCV `GaussianBlur`, clearly marked as optimized separable special case
- Kernels:
  - Gaussian
  - Sharpen
  - Laplacian
  - Sobel-X
  - Sobel-Y

Output:

- Embedded CPU baseline table: ms/frame, FPS, Mpix/s, power if measurable.

Unblocks:

- Fair software baseline.
- Paper comparison section.

---

## Phase 2 - Software/CNN Evaluation

### 8. Select and freeze Alzheimer MRI dataset

What to do:

- Chọn một dataset chính:
  - Kaggle 4-class Alzheimer MRI nếu cần fast-track.
  - OASIS nếu muốn academic hơn nhưng setup nặng hơn.
- Freeze split:
  - train
  - validation
  - test
- Ghi rõ subject-level split nếu dataset cho phép, tránh data leakage.

Output:

- Dataset manifest.
- Class distribution table.
- Split seed.

Unblocks:

- Reproducible CNN evaluation.
- Paper application section.

### 9. Build preprocessing export pipeline

What to do:

- Tạo cùng một input MRI resize/crop policy cho tất cả branches.
- Export các branches:
  - Raw
  - Gaussian
  - Sharpen
  - Laplacian
  - Sobel-X
  - Sobel-Y
  - Sobel-magnitude
  - Unsharp Mask
- Với FPGA-equivalent preprocessing, dùng đúng Q8.8 kernel và saturation behavior.

Output:

- Folder dataset đã preprocess theo từng branch.
- Metadata JSON ghi kernel, scale, normalization.

Unblocks:

- CNN training/evaluation.
- Visual examples in paper.

### 10. Freeze downstream CNN protocol

What to do:

- Chọn model chính:
  - ResNet18 cho fast-track.
  - ResNet50 nếu có GPU/time.
- Giữ cùng architecture, training recipe, epochs, seed cho mọi preprocessing branch.
- Không tune riêng cho từng branch nếu muốn so sánh công bằng.

Output:

- Training config YAML/JSON.
- Fixed model protocol.

Unblocks:

- Accuracy/F1 comparison.
- Claim "downstream evaluation" hợp lệ.

### 11. Run branch-by-branch CNN evaluation

What to do:

- Train/evaluate từng branch với cùng split.
- Report:
  - Accuracy
  - Macro-F1
  - Precision
  - Recall
  - confusion matrix
- Nếu thời gian cho phép, chạy 3 seeds và report mean/std.

Output:

- Metrics table.
- Confusion matrices.
- Best checkpoint per branch.

Unblocks:

- Main application result.
- Decision preprocessing nào preserves/degrades discriminative features.

### 12. Interpret results conservatively

What to do:

- Nếu một branch tốt hơn Raw: viết là "improved in this experimental setting".
- Nếu một branch tệ hơn Raw: viết là "degrades discriminative information".
- Nếu không khác biệt rõ: viết là "hardware preprocessing preserves classifier performance".

Output:

- Discussion notes.
- Final conclusion wording.

Unblocks:

- Paper discussion and conclusion.

---

## Phase 3 - Paper Writing

### 13. Rewrite title and abstract around preprocessing accelerator

What to do:

- Title direction:
  - `Runtime-Configurable FPGA Preprocessing Accelerator for Downstream Alzheimer MRI Classification`
- Abstract phải có đủ:
  - runtime-configurable 5x5 FPGA core
  - streaming one-pixel-per-clock
  - post-route timing/resource/power
  - downstream CNN evaluation
  - conservative claim về preprocessing impact

Output:

- New title.
- New abstract.

Unblocks:

- Coherent paper positioning.

### 14. Update architecture section for Design B

What to do:

- Mô tả:
  - addressless SRL-based window generator
  - 6-stage MAC
  - coeff_q shadow register
  - runtime kernel load only during idle
  - Q8.8 coefficient format
- Nói rõ Design B không tăng số tầng MAC.

Output:

- Architecture section.
- Updated block diagram.

Unblocks:

- Novelty claim.

### 15. Add hardware result section

What to do:

- Report:
  - RTL validation
  - post-route Fmax
  - resource utilization
  - power
  - throughput
  - ARM/Raspberry Pi baseline
- Nếu 200 MHz chỉ post-synthesis, ghi là feasibility result, không ghi là final.

Output:

- Hardware results tables.

Unblocks:

- Reviewer-ready hardware evidence.

### 16. Add downstream Alzheimer evaluation section

What to do:

- Report dataset, split, CNN protocol, preprocessing branches, metrics.
- Include visual examples of Raw/Gaussian/Sharpen/Laplacian/Sobel.
- So sánh Raw vs preprocessed branches.

Output:

- Main application result table.
- Confusion matrices.

Unblocks:

- Alzheimer paper contribution.

### 17. Related work and citation cleanup

What to do:

- Verify DOI/BibTeX cho các nhóm citation:
  - Sobel + CNN/MRI
  - extended/multi-direction Sobel
  - cortical thickness/boundary features in Alzheimer
  - preprocessing for Alzheimer classification
  - FPGA 2D convolution
- Không cite paper vượt quá claim thật.

Output:

- Clean `references.bib`.
- Related work section.

Unblocks:

- Submission-quality paper.

### 18. Final reproducibility package

What to do:

- Gom scripts:
  - RTL regression
  - Vivado timing/power
  - CPU benchmark
  - preprocessing export
  - CNN training/evaluation
- Ghi command lines trong README.

Output:

- Reproducibility checklist.
- Artifact folder/report.

Unblocks:

- Defense/demo/submission.

---

## RISK FLAG - highest-risk item

Highest-risk item: downstream CNN evaluation with a clean dataset split.

Lý do:

- Nếu bỏ post-route 200 MHz, paper vẫn có thể fallback về 146 MHz post-route.
- Nếu bỏ Raspberry Pi benchmark, paper vẫn còn hardware validation.
- Nhưng nếu bỏ CNN evaluation, title Alzheimer preprocessing không còn được chứng minh; paper sẽ quay lại thành một paper FPGA image filtering chung.

Mitigation:

- Fast-track ResNet18 trước.
- Chỉ dùng một dataset chính.
- Freeze split sớm.
- Chạy Raw vs Gaussian vs Laplacian vs Sobel-magnitude trước, thêm các branch khác sau.

---

## Fast-track path - minimum viable paper

Nếu thời gian hạn chế, làm tối thiểu theo thứ tự này:

1. Hardware:
   - Giữ post-route 146 MHz làm official claim.
   - Chỉ report Design B 200 MHz là post-synthesis feasibility nếu chưa route xong.
   - Run RTL regression cho 5 kernel cũ + Sobel-X/Y.

2. Software baseline:
   - Chạy Raspberry Pi naive C 5x5 single-thread.
   - Chạy OpenCV `filter2D` single-thread.
   - Không lấy desktop Ryzen làm baseline chính.

3. CNN:
   - Dataset Kaggle Alzheimer MRI 4-class.
   - Model ResNet18.
   - Branches tối thiểu:
     - Raw
     - Gaussian
     - Laplacian
     - Sobel-magnitude
   - Metrics:
     - Accuracy
     - Macro-F1
     - confusion matrix

4. Paper:
   - Claim chính: runtime-configurable FPGA preprocessing core + downstream evaluation.
   - Không claim preprocessing luôn cải thiện accuracy.
   - Không claim FPGA thắng desktop CPU.

---

## Sobel-like 5x5 Q8.8 kernel values

Definition:

- Base derivative vector: `[-1, -2, 0, 2, 1]`
- Base smoothing vector: `[1, 4, 6, 4, 1]`
- Integer scale: `S = 5`
- FPGA coefficient format: signed 16-bit integer, interpreted as Q8.8, normalized by `>>> 8`.
- This scale keeps an ideal full step response near 8-bit range because positive coefficient sum is `48 * 5 = 240`.

### Sobel-X 5x5, Q8.8 integer coefficients

```text
[
  [ -5, -10,   0,  10,   5],
  [-20, -40,   0,  40,  20],
  [-30, -60,   0,  60,  30],
  [-20, -40,   0,  40,  20],
  [ -5, -10,   0,  10,   5]
]
```

Flattened row-major:

```text
-5, -10, 0, 10, 5,
-20, -40, 0, 40, 20,
-30, -60, 0, 60, 30,
-20, -40, 0, 40, 20,
-5, -10, 0, 10, 5
```

### Sobel-Y 5x5, Q8.8 integer coefficients

```text
[
  [ -5, -20, -30, -20,  -5],
  [-10, -40, -60, -40, -10],
  [  0,   0,   0,   0,   0],
  [ 10,  40,  60,  40,  10],
  [  5,  20,  30,  20,   5]
]
```

Flattened row-major:

```text
-5, -20, -30, -20, -5,
-10, -40, -60, -40, -10,
0, 0, 0, 0, 0,
10, 40, 60, 40, 10,
5, 20, 30, 20, 5
```

### Negative-direction kernels for no-RTL-change magnitude

Nếu giữ core hiện tại và không thêm signed output mode, cần thêm hai kernel đảo dấu:

- `sobel_neg_x5 = -sobel_x5`
- `sobel_neg_y5 = -sobel_y5`

Then software magnitude can be approximated as:

```text
abs_gx = max(output(+Gx), output(-Gx))
abs_gy = max(output(+Gy), output(-Gy))
sobel_magnitude = clip(abs_gx + abs_gy, 0, 255)
```

This avoids losing negative gradients caused by RGB888 saturation.

---

## Execution status - 2026-05-28

### Completed locally

1. Sobel-like 5x5 kernels added to RTL verification flow.

Output:

- `sobel_x5` and `sobel_y5` added to:
  - `python/prepare_case.py`
  - `python/golden_model.py`
  - `python/run_d455_fullhd_rtl_frame.py`
  - `scripts/run_regression.ps1`
  - CPU benchmark scripts

Result:

- RTL regression PASS for 9/9 kernels:
  - `identity5`
  - `gaussian5`
  - `sharpen5`
  - `emboss5`
  - `laplacian5`
  - `sobel_x5`
  - `sobel_y5`
  - `sobel_neg_x5`
  - `sobel_neg_y5`
- Each 16x16 case produced 144 valid outputs and 0 mismatches.

2. Design B post-route timing closure completed.

Output:

- `scripts/run_impl_fmax_sweep_design_b.tcl`
- `vivado_project/fmax_sweep_impl_design_b/impl_fmax_sweep_summary.csv`
- `vivado_project/fmax_sweep_impl_design_b/200MHz/timing_post_route.rpt`
- `vivado_project/fmax_sweep_impl_design_b/200MHz/util_post_route.rpt`

Result:

```text
200 MHz post-route PASS
WNS = +0.250 ns
WHS = +0.069 ns
Fmax estimate = 210.53 MHz
DSP = 75
BRAM = 0
Slice LUTs = 7,236
Slice Registers = 1,727
```

This unblocks the official 200 MHz hardware claim for Design B, with the condition that the coefficient-stationary protocol is documented: kernel coefficients are updated only while `valid_in=0`.

3. SAIF-annotated power report generated for Design B.

Output:

- `sim/activity_design_b_200MHz.saif`
- `scripts/report_power_design_b.tcl`
- `vivado_project/fmax_sweep_impl_design_b/200MHz/power_post_route_saif.rpt`

Result:

```text
Total On-Chip Power = 0.421 W
Dynamic Power       = 0.329 W
Device Static Power = 0.092 W
Confidence Level    = Medium
Design Nets Matched = 4%
```

Note:

- Power confidence is better than the previous 1% net-match report, but still not full signoff.
- Use it as SAIF-annotated estimate, not board-measured power.

4. CPU software baselines extended.

Output:

- `python/benchmark_cpu_gaussian.py`
- `python/benchmark_naive_c_5x5.c`

Result on Ryzen 7 5800H, 1080p:

| Baseline | Gaussian | Sharpen | Laplacian | Sobel-X | Sobel-Y |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Naive C 5x5, 1 thread | 44.8 Mpix/s | 34.1 Mpix/s | 32.9 Mpix/s | 35.4 Mpix/s | 39.0 Mpix/s |
| OpenCV filter2D, 1 thread | 118.7 Mpix/s | 139.2 Mpix/s | 215.3 Mpix/s | 143.0 Mpix/s | 143.2 Mpix/s |
| FPGA Design B post-route | 200.0 Mpix/s | 200.0 Mpix/s | 200.0 Mpix/s | 200.0 Mpix/s | 200.0 Mpix/s |

Interpretation:

- FPGA Design B clearly beats naive C on desktop and should be much stronger against ARM/Raspberry Pi naive C.
- OpenCV `GaussianBlur` remains a special optimized/separable baseline and should not be the main comparison for arbitrary 5x5 kernels.

### Still blocked by external inputs

1. Raspberry Pi / ARM benchmark:

- Needs a Raspberry Pi, Zynq PS, or other ARM Cortex-A target.
- The C benchmark is now portable and ready to compile on Linux:

```bash
gcc -O3 -march=native python/benchmark_naive_c_5x5.c -o python/benchmark_naive_c_5x5
python/benchmark_naive_c_5x5 20 5
```

2. Alzheimer MRI CNN evaluation:

- Needs dataset selection/download and clean train/validation/test split.
- This remains the highest-risk item for the Alzheimer-specific paper claim.
