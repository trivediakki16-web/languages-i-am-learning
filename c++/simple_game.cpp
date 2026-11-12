// Use g++ simple_game.cpp -o simple_game.exe -lgdi32 -mwindows to compile this code on Windows.
// And for linux good luck because you have to change the code 
// to linux standerds like for x11 or wayland or sdl2 or something else. but i herd linux has good 
// graphical libraries like sdl2 or opengl or vulkan. but this code is for windows only.                                       
#include <windows.h>
#include <string>

// Global game variables
float playerX = 100.0f;
float playerY = 400.0f;
float playerVelocityY = 0.0f;
int playerSize = 40;
int timer = 20;
int frameCounter = 0;
bool gameover = false;

// Movement Settings
const float GRAVITY = 0.6f;
const float JUMP_FORCE = -25.0f;
const float MOVE_SPEED = 7.0f;
const int GROUND_Y = 500; // Y coordinate of the floor

// Target configurations
int targetX = 400;
int targetY = 300;
int targetSize = 25;

int score = 0;
int windowWidth = 800;
int windowHeight = 600;

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR pCmdLine, int nCmdShow) {
    const char CLASS_NAME[] = "GravityGameClass";

    WNDCLASS wc = { };
    wc.lpfnWndProc   = WindowProc;
    wc.hInstance     = hInstance;
    wc.lpszClassName = CLASS_NAME;
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);

    RegisterClass(&wc);

    HWND hwnd = CreateWindowEx(
        0, CLASS_NAME, "Smooth Gravity Game!", 
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
        CW_USEDEFAULT, CW_USEDEFAULT, windowWidth, windowHeight,
        NULL, NULL, hInstance, NULL
    );

    if (hwnd == NULL) return 0;

    ShowWindow(hwnd, nCmdShow);

    // Game loop timer (~60 updates per second)
    SetTimer(hwnd, 1, 16, NULL);

    MSG msg = { };
    while (GetMessage(&msg, NULL, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
        case WM_DESTROY:
            KillTimer(hwnd, 1);
            PostQuitMessage(0);
            return 0;

        case WM_TIMER: {
            if (gameover) return 0;
            // 1. SMOOTH KEYBOARD INPUTS (Reads system keys instantly every frame)
            if (GetAsyncKeyState(VK_LEFT) & 0x8000) {
                playerX -= MOVE_SPEED;
            }
            if (GetAsyncKeyState(VK_RIGHT) & 0x8000) {
                playerX += MOVE_SPEED;
            }
            // Up Arrow or Spacebar to jump (only allowed if standing on the ground)
            if ((GetAsyncKeyState(VK_UP) & 0x8000) || (GetAsyncKeyState(VK_SPACE) & 0x8000)) {
                if (playerY >= GROUND_Y - playerSize) {
                    playerVelocityY = JUMP_FORCE;
                }
            }

            frameCounter++;
            if (frameCounter >= 60){
                timer--;
                frameCounter = 0;

                if (timer <= 0){
                    timer = 0;
                    gameover = true;
                }
            }

            // 2. GRAVITY & PHYSICS
            playerVelocityY += GRAVITY; // Continuous downward pull
            playerY += playerVelocityY; // Apply velocity to position

            // Floor collision
            if (playerY >= GROUND_Y - playerSize) {
                playerY = GROUND_Y - playerSize;
                playerVelocityY = 0.0f; // Stop falling
            }

            // Keep player inside left/right screen bounds
            if (playerX < 0) playerX = 0;
            if (playerX > windowWidth - playerSize - 20) playerX = windowWidth - playerSize - 20;

            // 3. COLLISION DETECTION
            if (playerX < targetX + targetSize &&
                playerX + playerSize > targetX &&
                playerY < targetY + targetSize &&
                playerY + playerSize > targetY) 
            {
                score++;
                // Relocate target to a new random location above the ground
                targetX = 50 + (rand() % (windowWidth - 150));
                targetY = 100 + (rand() % (GROUND_Y - 100));
            }

            // Request window redraw
            InvalidateRect(hwnd, NULL, FALSE); // FALSE avoids clearing background here to prevent flashes
            return 0;
        }

        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);

            // --- DOUBLE BUFFERING IMPLEMENTATION ---
            // Create a temporary "virtual canvas" in memory
            HDC hdcMem = CreateCompatibleDC(hdc);
            HBITMAP hbmMem = CreateCompatibleBitmap(hdc, windowWidth, windowHeight);
            HGDIOBJ hOld = SelectObject(hdcMem, hbmMem);

            // 1. Clear memory canvas background (Sky Color)
            HBRUSH skyBrush = CreateSolidBrush(RGB(200, 230, 255));
            RECT bgRect = { 0, 0, windowWidth, windowHeight };
            FillRect(hdcMem, &bgRect, skyBrush);
            DeleteObject(skyBrush);

            // 2. Draw Floor (Green Platform)
            HBRUSH floorBrush = CreateSolidBrush(RGB(34, 139, 34));
            RECT floorRect = { 0, GROUND_Y, windowWidth, windowHeight };
            FillRect(hdcMem, &floorRect, floorBrush);
            DeleteObject(floorBrush);

            // 3. Draw Player (Blue Square)
            HBRUSH playerBrush = CreateSolidBrush(RGB(0, 100, 255));
            RECT playerRect = { (int)playerX, (int)playerY, (int)playerX + playerSize, (int)playerY + playerSize };
            FillRect(hdcMem, &playerRect, playerBrush);
            DeleteObject(playerBrush);

            // 4. Draw Target (Red Star/Square)
            HBRUSH targetBrush = CreateSolidBrush(RGB(255, 50, 50));
            RECT targetRect = { targetX, targetY, targetX + targetSize, targetY + targetSize };
            FillRect(hdcMem, &targetRect, targetBrush);
            DeleteObject(targetBrush);

            // 5. Draw Score and Timer UI
            SetBkMode(hdcMem, TRANSPARENT);
            std::string scoreText = "Score: " + std::to_string(score);
            TextOut(hdcMem, 20, 20, scoreText.c_str(), static_cast<int>(scoreText.length()));

            std::string timeText = "Time Left: " + std::to_string(timer) + "s";
            TextOut(hdcMem, 650, 20, timeText.c_str(), static_cast<int>(timeText.length()));

            // Draw the game-over panel after the game so it appears on top.
            if (gameover) {
                HBRUSH gameOverBrush = CreateSolidBrush(RGB(50, 50, 50));
                RECT gameOverRect = { 200, 150, 600, 350 };
                FillRect(hdcMem, &gameOverRect, gameOverBrush);
                DeleteObject(gameOverBrush);

                TextOut(hdcMem, 350, 180, "GAME OVER!", 10);
                std::string finalScore = "Final Score: " + std::to_string(score);
                TextOut(hdcMem, 340, 220, finalScore.c_str(), static_cast<int>(finalScore.length()));
            }

            // Copy the completed memory canvas to the screen.
            BitBlt(hdc, 0, 0, windowWidth, windowHeight, hdcMem, 0, 0, SRCCOPY);

            // Restore and release the GDI objects used for double buffering.
            SelectObject(hdcMem, hOld);
            DeleteObject(hbmMem);
            DeleteDC(hdcMem);

            EndPaint(hwnd, &ps);
            return 0;
        }
    }

    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}
