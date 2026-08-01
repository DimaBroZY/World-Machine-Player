using Godot;
using System;
using System.Runtime.InteropServices;
using SystemMutex = System.Threading.Mutex;

public partial class SingleInstanceGuard : Node
{
 
	private const string MutexName = @"Local\WorldMachinePlayer_9F3A1B2C-6E4D-4B7E-9F0A-2C6B1E5A7D3F";
	private const string WindowTitle = "World Machine Player"; 

	private static SystemMutex _mutex;

	public override void _EnterTree()
	{
		if (OS.GetName() != "Windows")
			return; 

		bool createdNew;
		_mutex = new SystemMutex(true, MutexName, out createdNew);

		if (!createdNew)
		{
			BringExistingInstanceToFront();
			GetTree().Quit();
		}
	}

	private void BringExistingInstanceToFront()
	{
		IntPtr hWnd = FindWindowW(null, WindowTitle);
		if (hWnd == IntPtr.Zero)
			return;

		if (IsIconic(hWnd))
			ShowWindow(hWnd, SW_RESTORE);

		SetForegroundWindow(hWnd);
	}

	private const int SW_RESTORE = 9;

	[DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
	private static extern IntPtr FindWindowW(string lpClassName, string lpWindowName);

	[DllImport("user32.dll")]
	private static extern bool SetForegroundWindow(IntPtr hWnd);

	[DllImport("user32.dll")]
	private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

	[DllImport("user32.dll")]
	private static extern bool IsIconic(IntPtr hWnd);
}
