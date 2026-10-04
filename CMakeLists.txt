cmake_minimum_required(VERSION 3.16)

project(first VERSION 0.1 LANGUAGES CXX)

# Жесткая фиксация стандарта для поддержки Memory Ordering и Lock-Free структур
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(OpenSSL REQUIRED)

qt_standard_project_setup(REQUIRES 6.8)

# Секция исходных кодов (Translation Units) и заголовочных файлов (для MOC)
qt_add_executable(appfirst
    main.cpp
    # --- Крипто-ядро ---
    CryptoVault.h
    CryptoVault.cpp
    # --- Конфигурации ---
    SettingsManager.h
    SettingsManager.cpp
    # --- Сетевой стек (P2P) ---
    ITransport.h
    P2pEngine.h
    P2pEngine.cpp
    # --- Хранилище (Zero-Copy) ---
    MemoryMappedStorage.h
    MemoryMappedStorage.cpp
    # --- Интерфейсные модели (UI Bridge) ---
    ChatViewModel.h
    ChatViewModel.cpp
    ContactsModel.h
    ContactsModel.cpp
    # --- Структуры данных (POD) ---
    CoreStructures.h 
)

qt_add_qml_module(appfirst
    URI first
    VERSION 1.0
    QML_FILES
        Main.qml
    RESOURCES
        fonts/JetBrainsMono-Regular.ttf
        fonts/PTSans-Regular.ttf
        fonts/Roboto-Regular.ttf
)

set_target_properties(appfirst PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# Линковка динамических библиотек. OpenSSL::Crypto критически важен для EVP_*.
target_link_libraries(appfirst
    PRIVATE Qt6::Quick
    PRIVATE OpenSSL::Crypto
    PRIVATE OpenSSL::SSL
)
if(UNIX AND NOT APPLE)
    # 1. Загружаем системный локатор библиотек Linux
    find_package(PkgConfig REQUIRED)
    
    # 2. Ищем физические пути к libsecret и создаем виртуальную цель (IMPORTED_TARGET)
    pkg_check_modules(LIBSECRET REQUIRED IMPORTED_TARGET libsecret-1)
    
    # 3. Линкуем (привязываем) найденную библиотеку к нашему исполняемому файлу
    target_link_libraries(appfirst PRIVATE PkgConfig::LIBSECRET)
endif()

include(GNUInstallDirs)
install(TARGETS appfirst
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)