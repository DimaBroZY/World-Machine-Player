using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;

namespace WorldMachinePlayer.Smtc;

internal static class StartMenuShortcutHelper
{
	private static readonly PropertyKey AppUserModelIdKey =
		new(new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), 5);

	public static void EnsureShortcut(string appUserModelId, string displayName)
	{
		try
		{
			var exePath = Environment.ProcessPath;
			if (string.IsNullOrEmpty(exePath) || !File.Exists(exePath))
				return;

			if (Path.GetFileNameWithoutExtension(exePath)
				.Equals("Godot", StringComparison.OrdinalIgnoreCase))
				return;

			var shortcutPath = Path.Combine(
				Environment.GetFolderPath(Environment.SpecialFolder.StartMenu),
				"Programs",
				displayName + ".lnk");

			if (File.Exists(shortcutPath) && ShortcutPointsTo(shortcutPath, exePath))
				return;

			CreateShortcut(shortcutPath, exePath, appUserModelId);
		}
		catch
		{
			// Shortcut creation is best-effort; must not crash the app.
		}
	}

	private static void CreateShortcut(string lnkPath, string exePath, string appUserModelId)
	{
		var link = (IShellLinkW)new CShellLink();
		var persist = (IPersistFile)link;

		link.SetPath(exePath);
		link.SetWorkingDirectory(Path.GetDirectoryName(exePath) ?? "");
		link.SetDescription("World Machine Player");
		link.SetIconLocation(exePath, 0);

		var store = (IPropertyStore)link;
		using var pv = PropVariant.FromString(appUserModelId);
		var key = AppUserModelIdKey;
		store.SetValue(ref key, pv);
		store.Commit();

		persist.Save(lnkPath, true);
	}

	private static bool ShortcutPointsTo(string lnkPath, string exePath)
	{
		try
		{
			var link = (IShellLinkW)new CShellLink();
			((IPersistFile)link).Load(lnkPath, 0);
			var sb = new StringBuilder(260);
			var data = new WIN32_FIND_DATAW();
			link.GetPath(sb, sb.Capacity, ref data, 0);
			return string.Equals(sb.ToString(), exePath, StringComparison.OrdinalIgnoreCase);
		}
		catch
		{
			return false;
		}
	}

	[ComImport, Guid("00021401-0000-0000-C000-000000000046")]
	private class CShellLink { }

	[ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
	 Guid("000214F9-0000-0000-C000-000000000046")]
	private interface IShellLinkW
	{
		void GetPath([Out] StringBuilder pszFile, int cchMaxPath, ref WIN32_FIND_DATAW pfd, uint fFlags);
		void GetIDList(out IntPtr ppidl);
		void SetIDList(IntPtr pidl);
		void GetDescription([Out] StringBuilder pszName, int cchMaxName);
		void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
		void GetWorkingDirectory([Out] StringBuilder pszDir, int cchMaxPath);
		void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
		void GetArguments([Out] StringBuilder pszArgs, int cchMaxPath);
		void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
		void GetHotKey(out ushort pwHotkey);
		void SetHotKey(ushort wHotKey);
		void GetShowCmd(out int piShowCmd);
		void SetShowCmd(int iShowCmd);
		void GetIconLocation([Out] StringBuilder pszIconPath, int cchIconPath, out int piIcon);
		void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
		void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, uint dwReserved);
		void Resolve(IntPtr hwnd, uint fFlags);
		void SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
	}

	[ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown),
	 Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
	private interface IPropertyStore
	{
		void GetCount(out uint cProps);
		void GetAt(uint iProp, out PropertyKey pkey);
		void GetValue(ref PropertyKey key, PropVariant pv);
		void SetValue(ref PropertyKey key, PropVariant pv);
		void Commit();
	}

	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	private struct WIN32_FIND_DATAW
	{
		public uint dwFileAttributes;
		public System.Runtime.InteropServices.ComTypes.FILETIME ftCreationTime;
		public System.Runtime.InteropServices.ComTypes.FILETIME ftLastAccessTime;
		public System.Runtime.InteropServices.ComTypes.FILETIME ftLastWriteTime;
		public uint nFileSizeHigh;
		public uint nFileSizeLow;
		public uint dwReserved0;
		public uint dwReserved1;
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
		public string cFileName;
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)]
		public string cAlternateFileName;
	}

	[StructLayout(LayoutKind.Sequential)]
	private struct PropertyKey(Guid formatId, int propertyId)
	{
		readonly Guid _formatId = formatId;
		readonly int _propertyId = propertyId;
	}

	[StructLayout(LayoutKind.Explicit)]
	private sealed class PropVariant : IDisposable
	{
		[FieldOffset(0)] private ushort _vt;
		[FieldOffset(8)] private IntPtr _ptr;

		public static PropVariant FromString(string value)
		{
			var pv = new PropVariant
			{
				_vt = (ushort)VarEnum.VT_LPWSTR,
				_ptr = Marshal.StringToCoTaskMemUni(value)
			};
			return pv;
		}

		public void Dispose()
		{
			if (_ptr != IntPtr.Zero)
			{
				Marshal.FreeCoTaskMem(_ptr);
				_ptr = IntPtr.Zero;
			}
		}
	}
}
