# PM Standards Comparison & Process Design App

A Flutter application that consolidates PMBOK 7th Edition, PRINCE2, and ISO 21502 standards, providing intelligent comparisons and tailored process recommendations for project managers, students, and researchers.

## 🎯 **Assignment Coverage**

### ✅ **Fully Implemented**
- **Standards Repository**: All 3 standards (PMBOK 7, PRINCE2, ISO 21502) as searchable PDFs
- **Comparison Engine**: 18 curated topics with side-by-side comparisons and deep linking
- **Insights Dashboard**: Similarities, Differences, and Unique Points (3-4 lines each)
- **Tailored Process Generation**: Dynamic recommendations based on project characteristics
- **Search & Navigation**: Full PDF search, bookmarks, table of contents
- **Modern UI/UX**: Material Design with dark/light theme support

### 📋 **Missing Components**
- **WBS (Work Breakdown Structure)**: To be created separately
- **Process Design Documentation**: Detailed justification for recommendations
- **GitHub Repository**: For easy access and review

## 🚀 **How to Run in VS Code**

### **Prerequisites**
1. **Install Flutter SDK** (3.0+)
   - Download from: https://flutter.dev/docs/get-started/install/windows
   - Add Flutter to PATH environment variable
   - Verify: `flutter doctor` in terminal

2. **Install VS Code Extensions**
   - Flutter Extension Pack
   - Dart Extension Pack

3. **Install Visual Studio 2022** (for Windows desktop)
   - Install "Desktop development with C++" workload
   - Include Windows 10/11 SDK

### **Step-by-Step Setup**

#### **1. Clone/Download Project**
```bash
# If using Git
git clone <repository-url>
cd pm4_app

# Or download ZIP and extract to pm4_app folder
```

#### **2. Open in VS Code**
```bash
# Navigate to project folder
cd pm4_app

# Open VS Code
code .
```

#### **3. Install Dependencies**
```bash
# In VS Code terminal (Ctrl+`)
flutter pub get
```

#### **4. Verify Setup**
```bash
# Check Flutter installation
flutter doctor

# Should show:
# ✓ Flutter (Channel stable, 3.x.x)
# ✓ Windows Version (Installed version of Windows is version 10 or higher)
# ✓ Visual Studio - develop for Windows (Visual Studio Community 2022)
# ✓ Android toolchain (if needed)
```

#### **5. Run the Application**

**Option A: VS Code UI**
1. Open `lib/main.dart`
2. Press `F5` or click "Run and Debug"
3. Select "Windows (Debug)" from dropdown
4. Click green play button

**Option B: Terminal**
```bash
# Run on Windows desktop
flutter run -d windows

# Run on Chrome (web)
flutter run -d chrome

# Run on Android (if connected)
flutter run -d android
```

#### **6. Build Executable**
```bash
# Build Windows executable
flutter build windows

# Output: build/windows/x64/runner/Release/pm4_app.exe
```

## 📱 **App Features**

### **Home Screen**
- Display all 3 standards as clickable cards
- Global search bar for topic search
- Recent search chips
- Theme toggle (dark/light mode)

### **Reader Screen**
- Full PDF viewer with search capabilities
- Bookmark management
- Table of contents navigation
- Deep linking to specific pages

### **Compare Screen**
- 18 curated topics (Governance, Risk Management, etc.)
- Fuzzy search with synonyms
- Side-by-side comparison with deep links
- 3-4 line insights for each topic

### **Generate Screen**
- Tailored process recommendations
- Multiple project characteristics:
  - Project Type (IT, Construction, Healthcare, etc.)
  - Complexity (Simple, Moderate, Complex)
  - Delivery Method (Predictive, Agile, Hybrid)
  - Governance Level (Minimal, Standard, Rigorous)
  - Risk Appetite (Low, Medium, High)

## 🏗️ **Architecture**

### **State Management**
- `Provider` pattern for state management
- `ThemeProvider`: Dark/light mode
- `BookmarksProvider`: PDF bookmarks
- `SearchProvider`: Recent searches
- `IndexProvider`: Dynamic content indexing

### **Services**
- `StandardsIndexService`: PDF parsing and content extraction
- Dynamic topic mapping and insight generation
- Caching for performance optimization

### **Assets**
- PDF files: `pmbok7.pdf`, `prince2.pdf`, `iso21502.pdf`
- JSON configurations: `compare_topics.json`, `baseline_rules.json`

## 🔧 **Troubleshooting**

### **Common Issues**

**1. Build Errors**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d windows
```

**2. PDF Not Loading**
- Ensure PDF files are in `assets/` folder
- Check `pubspec.yaml` assets section
- Run `flutter pub get` after adding assets

**3. Syncfusion License**
- App uses Syncfusion PDF viewer (free for students)
- No license key required for development

**4. Windows Build Issues**
- Ensure Visual Studio 2022 is installed
- Install Windows 10/11 SDK
- Run `flutter doctor` to verify setup

### **Performance Tips**
- PDFs are lazy-loaded to prevent UI freezes
- Caching is implemented for instant topic re-opening
- Large PDFs (like PRINCE2) may take 2-3 seconds to load initially

## 📊 **Comparison Methodology**

### **Topic Selection**
18 core topics covering:
- **Core Topics**: Governance, Risk, Stakeholders, Quality, etc.
- **Depth Topics**: Integration, Procurement, Sustainability, etc.

### **Insight Generation**
- **Similarities**: Common practices across all 3 standards
- **Differences**: Unique terminologies and methodologies
- **Unique Points**: Standard-specific contributions

### **Deep Linking**
- Exact page mapping for each topic
- Override system for manual page corrections
- Fallback to PDF search if page not found

## 🎓 **Educational Value**

This application demonstrates:
- **Technical Skills**: Flutter development, PDF processing, state management
- **Analytical Skills**: Cross-standard comparison and insight generation
- **Process Design**: Evidence-based project methodology recommendations
- **User Experience**: Intuitive navigation and modern UI design

## 📝 **Future Enhancements**

- **Visual Maps**: Venn diagrams for topic overlap
- **Export Features**: Save comparisons as PDF/Word
- **Advanced Search**: Semantic search across all standards
- **Collaboration**: Share bookmarks and insights
- **Analytics**: Usage tracking and popular topics

## 👥 **Group Assignment**

**Team Members**: [Add your names]
**Course**: [Course name]
**Instructor**: [Instructor name]
**Due Date**: [Due date]

## 📄 **License**

This project is created for educational purposes as part of a university assignment.

---

**Built with Flutter 💙 | Powered by Syncfusion PDF Viewer**