# Elite Destiny Academy Finance Management System

A comprehensive Flutter-based financial management system designed for educational institutions. Built for Elite Destiny Academy to manage student fees, payments, receipts, item requirements, and financial reporting.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Web%20%7C%20Linux-lightgrey)
![License](https://img.shields.io/badge/License-Private-red)

---

## Features

### 🏫 Administration
- **Dashboard** — Real-time financial overview with revenue, outstanding fees, collection rates, grade distribution charts, and recent activity
- **Student Management** — Onboard students, manage enrollment, and track student records
- **Grade Management** — Create and manage academic grades/classes
- **Fee Structure** — Define tuition, transport, lunch, remedial, and other fee types per grade and term
- **Other Fees** — Manage miscellaneous fees outside the standard fee structure
- **User Management** — Role-based access control for Admin and Accountant users
- **Student Promotion** — Bulk promote students to the next grade with preview and confirmation
- **Organization Settings** — Configure school name, logo, address, and contact details

### 💰 Payments & Accounting
- **Payment Recording** — Record student fee payments with auto-allocation across fee types
- **Student Selection** — Search and select students for payment processing
- **Payment History** — Complete transaction audit trail
- **Credit Balance Tracking** — Automatic overpayment tracking and carry-forward

### 🧾 Thermal Receipt Printing
- **Thermal Printer Support** — Network (TCP/IP) thermal printer integration via ESC/POS
- **Receipt Preview** — On-screen preview before printing
- **PDF Export** — Generate and save receipts as PDF documents
- **Print History & Audit** — Track all printed receipts with reprint capability
- **Printer Settings** — Discover, configure, and test thermal printers

### 📦 Item Ledger / Requirements
- **Requirement Lists** — Define required items (uniforms, books, supplies) per term
- **Student Requirements** — Assign requirement lists to students and track fulfillment
- **Item Transactions** — Record item deliveries and monetary contributions
- **Transaction History** — Full audit trail of item transactions with receipt links

### 📊 Financial Reports
- **Daily Collections** — Daily payment summary with transaction counts
- **Revenue Summary** — Revenue breakdown by fee type, grade, and monthly trends
- **Outstanding Fees** — Student arrears and outstanding balance tracking
- **Collection Rate** — Fee collection performance metrics and analysis
- **Payment History** — Comprehensive payment transaction reports
- **Item Transactions** — Item ledger fulfillment and contribution reports
- **Student Statements** — Individual student financial statements
- **Export** — Download reports as PDF or Excel

### 🎨 UI/UX
- **Light & Dark Theme** — Full theme support with dynamic switching
- **Responsive Layout** — Side navigation layout optimized for desktop
- **Google Fonts** — Consistent typography using the Underdog font family
- **Charts & Visualizations** — Pie charts, bar charts, and progress indicators via fl_chart

---

## Tech Stack

| Layer              | Technology                                                      |
| ------------------ | --------------------------------------------------------------- |
| **Framework**      | Flutter 3.0+ (Windows, Web, Linux, macOS)                       |
| **Language**       | Dart 3.0+                                                       |
| **State Management** | Riverpod (`flutter_riverpod`, `StateNotifier`, `FutureProvider`) |
| **HTTP Client**    | Dio with auth interceptor                                       |
| **Auth**           | JWT tokens via `flutter_secure_storage`                         |
| **Printing**       | `esc_pos_utils_plus`, `printing` (PDF)                          |
| **Charts**         | `fl_chart`                                                      |
| **PDF Generation** | `pdf` package                                                   |
| **Fonts**          | `google_fonts`                                                  |
| **Environment**    | `flutter_dotenv`                                                |
| **Backend**        | .NET API hosted on Render                                       |

---

## Project Structure

```
lib/
├── main.dart                          # App entry point, routing, theme setup
├── models/                            # Data models
│   ├── fee_structure.dart
│   ├── grade.dart
│   ├── item_transaction.dart
│   ├── org_settings.dart
│   ├── other_fee.dart
│   ├── payment.dart
│   ├── payment_detail.dart
│   ├── printer_config.dart
│   ├── requirement_item.dart
│   ├── requirement_list.dart
│   ├── requirement_status.dart
│   ├── requirement_transaction_detail.dart
│   ├── requirement_transaction_history_entry.dart
│   ├── student_arrears.dart
│   ├── student_fee.dart
│   ├── student_promotion.dart
│   ├── student_requirement.dart
│   ├── thermal_receipt.dart
│   └── report/                        # Report-specific models
│       ├── collection_rate_report.dart
│       ├── daily_collection_report.dart
│       ├── item_transactions_report.dart
│       ├── outstanding_fees_report.dart
│       ├── payment_history_report.dart
│       ├── report_filter.dart
│       ├── report_summary.dart
│       ├── revenue_summary_report.dart
│       └── student_statement_report.dart
├── Pages/                             # UI screens
│   ├── dashboard.dart
│   ├── Auth/                          # Login screen
│   ├── Admin/                         # Admin screens
│   │   ├── admin_dashboard_screen.dart
│   │   ├── student_promotion_dialog.dart
│   │   ├── printer_settings_screen.dart
│   │   ├── report/                    # Report screens
│   │   └── requirement/               # Item ledger screens
│   └── Accountant/                    # Accountant screens
│       ├── accountant_dashboard.dart
│       ├── fee_structure_display_screen.dart
│       ├── print_history_screen.dart
│       ├── record_item_transaction_screen.dart
│       ├── students_display_screen.dart
│       ├── thermal_receipt_preview_screen.dart
│       └── payment/
├── provider/                          # Riverpod state providers
│   ├── auth_provider.dart
│   ├── dashboard_provider.dart
│   ├── fee_structure_provider.dart
│   ├── grade_provider.dart
│   ├── item_ledger_provider.dart
│   ├── other_fee_provider.dart
│   ├── payment_provider.dart
│   ├── print_audit_provider.dart
│   ├── promotion_provider.dart
│   ├── receipt_provider.dart
│   ├── settings_provider.dart
│   ├── student_provider.dart
│   ├── theme_provider.dart
│   ├── thermal_printer_provider.dart
│   ├── thermal_receipt_provider.dart
│   └── user_management.dart
├── services/                          # API & business logic services
│   ├── auth_service.dart
│   ├── auth_interceptor.dart
│   ├── delete_service.dart
│   ├── item_ledger_service.dart
│   ├── promotion_service.dart
│   ├── receipt_formatter.dart
│   ├── report_download_service.dart
│   ├── report_service.dart
│   ├── thermal_printer_service.dart
│   └── thermal_receipt_service.dart
├── utils/                             # Utilities
│   ├── animations.dart
│   ├── app_colors.dart
│   └── text_utils.dart
└── widgets/                           # Reusable widgets
    ├── activity_table.dart
    ├── confirmation_dialog.dart
    ├── dashboard_header.dart
    ├── date_range_picker_widget.dart
    ├── error_widget.dart
    ├── fee_breakdown_chart.dart
    ├── metric_card.dart
    ├── modal_form.dart
    ├── payment_detail_modal.dart
    ├── quick_action_button.dart
    ├── side_nav_layout.dart
    ├── student_distribution_widget.dart
    └── student_modal_form.dart
```

---

## Getting Started

### Prerequisites

- **Flutter SDK** 3.0+ — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** 3.0+
- **Visual Studio 2022** with C++ desktop development workload (for Windows builds)

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/graham005/Financial-Management-Frontend.git
   cd Financial-Management-Frontend
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and set your backend API URL:
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Enable Windows desktop (if building for Windows):**
   ```bash
   flutter config --enable-windows-desktop
   ```

5. **Run the application:**
   ```bash
   flutter run -d windows
   ```

### Build for Production

```bash
flutter build windows --release
```

The built application will be in `build/windows/x64/runner/Release/`.

---

## CI/CD & Auto-Updates

This project uses **GitHub Actions** to build and publish MSIX installers with auto-update support.

### How It Works

1. Push a version tag (e.g., `v1.0.0`) to trigger the build workflow
2. GitHub Actions builds the Windows MSIX package
3. Release assets (`EliteFinance.msix`) are published to GitHub Releases
4. Users install once; Windows auto-checks for updates every 24 hours

### Creating a Release

1. Update `msix_version` in `pubspec.yaml`
2. Commit and tag:
   ```bash
   git add .
   git commit -m "Release v1.0.1"
   git tag v1.0.1
   git push origin main --tags
   ```

### First-Time Installation (Users)

1. Download `EliteFinance.msix`from the [latest release](https://github.com/graham005/Financial-Management-Frontend/releases/latest)
2. Right-click `EliteFinance.msix` → **Run as Administrator**
3. Follow the on-screen prompts

### Required GitHub Secrets

| Secret             | Description                                  |
| ------------------ | -------------------------------------------- |
| `API_BASE_URL`     | Backend API URL                              |
| `CERT_PFX_BASE64`  | Base64-encoded `.pfx` signing certificate    |
| `CERT_PASSWORD`    | Password for the `.pfx` certificate          |

---

## Roles & Access

| Role         | Access                                                                 |
| ------------ | ---------------------------------------------------------------------- |
| **Admin**    | Full access: dashboard, students, grades, fees, users, reports, settings, item ledger |
| **Accountant** | Payments, student view, fee structure view, receipt printing, item transactions |

---

## Contributing

This is a private project for ElderMan Labs. For internal contributions:

1. Create a feature branch from `main`
2. Make your changes
3. Submit a pull request for review

---

## License

Private — All rights reserved. This software is proprietary to Elderman Labs.
