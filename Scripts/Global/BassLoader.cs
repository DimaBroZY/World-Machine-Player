using Godot;
using System;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using GodotFileAccess = Godot.FileAccess;

public partial class BassLoader : Node
{
	private static readonly string[] BassFiles =
	{
		"bass",
		"bass_aac",
		"bassflac",
		"bassopus"
	};

	private const string BinariesDir = "user://binaries";
	private const string SourceDir = "res://libs";


	public override void _Ready()
	{
		ExtractBassDllsToUserDir();
		LoadBassDll();
	}


	private string GetLibraryFileName(string baseName)
	{
		if (OperatingSystem.IsWindows())
			return $"{baseName}.dll";

		if (OperatingSystem.IsLinux())
			return $"lib{baseName}.so";

		return "";
	}


	private void ExtractBassDllsToUserDir()
	{
		string targetDir = ProjectSettings.GlobalizePath(BinariesDir);

		if (!Directory.Exists(targetDir))
		{
			Directory.CreateDirectory(targetDir);
			GD.Print($"BassLoader: создана директория {targetDir}");
		}

		foreach (string baseName in BassFiles)
		{
			string file = GetLibraryFileName(baseName);

			if (string.IsNullOrEmpty(file))
			{
				GD.PrintErr(
					$"BassLoader: неподдерживаемая ОС: {OS.GetName()}"
				);
				continue;
			}

			string sourcePath = GetSourceDllPath(file);
			string targetPath = Path.Combine(targetDir, file);

			if (!File.Exists(targetPath))
			{
				try
				{
					if (File.Exists(sourcePath))
					{
						File.Copy(sourcePath, targetPath, true);

						GD.Print(
							$"BassLoader: скопирован {file} в {targetDir}"
						);
					}
					else
					{
						byte[] data = GodotFileAccess.GetFileAsBytes(
							$"{SourceDir}/{file}"
						);

						if (data != null && data.Length > 0)
						{
							File.WriteAllBytes(targetPath, data);

							GD.Print(
								$"BassLoader: извлечён {file} из ресурсов в {targetDir}"
							);
						}
						else
						{
							GD.PrintErr(
								$"BassLoader: {file} не найден ни в файловой системе, ни в ресурсах"
							);
						}
					}
				}
				catch (Exception ex)
				{
					GD.PrintErr(
						$"BassLoader: ошибка извлечения {file}: {ex.Message}"
					);
				}
			}
		}
	}


	private string GetSourceDllPath(string fileName)
	{
		string[] possiblePaths =
		{
			Path.Combine(
				ProjectSettings.GlobalizePath("res://"),
				"libs",
				fileName
			),

			Path.Combine(
				OS.GetExecutablePath().GetBaseDir(),
				"libs",
				fileName
			),

			Path.Combine(
				Directory.GetCurrentDirectory(),
				"libs",
				fileName
			),

			Path.Combine(
				AppContext.BaseDirectory,
				"libs",
				fileName
			),

			Path.Combine(
				ProjectSettings.GlobalizePath("res://"),
				"addons",
				"ManagedBass",
				fileName
			),

			Path.Combine(
				OS.GetExecutablePath().GetBaseDir(),
				"addons",
				"ManagedBass",
				fileName
			),

			Path.Combine(
				Directory.GetCurrentDirectory(),
				"addons",
				"ManagedBass",
				fileName
			),

			Path.Combine(
				AppContext.BaseDirectory,
				"addons",
				"ManagedBass",
				fileName
			),
		};

		foreach (string path in possiblePaths)
		{
			if (File.Exists(path))
				return path;
		}

		return "";
	}


	private void LoadBassDll()
	{
		string userDir = ProjectSettings.GlobalizePath(BinariesDir);

		foreach (string baseName in BassFiles)
		{
			string fileName = GetLibraryFileName(baseName);

			if (string.IsNullOrEmpty(fileName))
				continue;

			string path = Path.Combine(userDir, fileName);

			if (!File.Exists(path))
			{
				GD.PrintErr(
					$"BassLoader: {fileName} не найден в {path}"
				);
				continue;
			}

			try
			{
				NativeLibrary.Load(path);

				GD.Print(
					$"BassLoader: {fileName} загружен из {path}"
				);
			}
			catch (Exception ex)
			{
				GD.PrintErr(
					$"BassLoader: ошибка загрузки {fileName}: {ex.Message}"
				);
			}
		}
	}


	static BassLoader()
	{
		NativeLibrary.SetDllImportResolver(
			Assembly.GetExecutingAssembly(),
			ResolveNative
		);
	}


	private static IntPtr ResolveNative(
		string libraryName,
		Assembly assembly,
		DllImportSearchPath? searchPath)
	{
		if (libraryName != "bass" &&
			libraryName != "bass_aac" &&
			libraryName != "bassflac" &&
			libraryName != "bassopus")
		{
			return IntPtr.Zero;
		}

		string fileName = OperatingSystem.IsWindows()
			? $"{libraryName}.dll"
			: $"lib{libraryName}.so";

		string userDir =
			ProjectSettings.GlobalizePath(BinariesDir);

		string path = Path.Combine(
			userDir,
			fileName
		);

		if (
			File.Exists(path) &&
			NativeLibrary.TryLoad(path, out IntPtr handle)
		)
		{
			GD.Print(
				$"BassLoader: {libraryName} загружен из {path}"
			);

			return handle;
		}


		foreach (
			string fallbackPath
			in BuildFallbackCandidates(fileName, assembly)
		)
		{
			if (
				File.Exists(fallbackPath) &&
				NativeLibrary.TryLoad(
					fallbackPath,
					out handle
				)
			)
			{
				GD.Print(
					$"BassLoader: {libraryName} загружен из fallback {fallbackPath}"
				);

				return handle;
			}
		}


		GD.PrintErr(
			$"BassLoader: {libraryName} не найден ни в одном из путей"
		);

		return IntPtr.Zero;
	}


	private static System.Collections.Generic.IEnumerable<string>
		BuildFallbackCandidates(
			string fileName,
			Assembly assembly)
	{
		yield return Path.Combine(
			AppContext.BaseDirectory,
			fileName
		);

		yield return Path.Combine(
			Path.GetDirectoryName(assembly.Location) ?? "",
			fileName
		);

		yield return Path.Combine(
			Directory.GetCurrentDirectory(),
			fileName
		);

		yield return Path.Combine(
			OS.GetExecutablePath().GetBaseDir(),
			fileName
		);
	}
}