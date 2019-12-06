import platform
import os
import argparse
import sys
import re

def run(commands):
    for command in commands:
        print("****Running " + command)
        sys.stdout.flush()
        os.system(command)

def rebase_path(path, cmp_path):
  pwd_list = re.split(r"\/|\\", cmp_path)
  path_list = re.split(r"\/|\\", path)
  min_len = min(len(pwd_list), len(path_list))
  start_pos = 0
  for start_pos in range(min_len):
    if pwd_list[start_pos] != path_list[start_pos]:
      break
  path_prefix = ["."]
  if start_pos < len(pwd_list):
    left_pwd_list = pwd_list[start_pos:]
    path_prefix.extend([".." for idx in range(len(left_pwd_list))])
  path_prefix.extend(path_list[start_pos:])
  full_path = ""
  full_path = '/'.join(path_prefix)
  print(full_path)
  return full_path

def build_for_msys(msys_path, boostdir, arch, prefix, ndkdir):
  if not os.path.exists(msys_path):
    raise Exception("Failed to find Msys")
  else:
    if not os.path.exists(prefix):
      print("Create directory %s"%prefix)
      os.makedirs(prefix)

    os.chdir(sys.path[0])
    current_dir = os.getcwd()

    args_array = ["--boost_dir="+boostdir,
                  "--arch="+arch,
                  "--prefix="+prefix,
                  ndkdir]

    msys_shell_cmd = os.path.join(msys_path, "msys2_shell.cmd")
    command = [msys_shell_cmd,
              "-no-start",
              "-here -c",
              "\"./build-android.bat %s > build_log.txt 2>&1\"" % ' '.join(args_array)]
    run([' '.join(command)])

def build_for_posix(boostdir, arch, prefix, ndkdir):
  if not os.path.exists(prefix):
    print("Create directory %s"%prefix)
    os.makedirs(prefix)

  os.chdir(sys.path[0])
  args_array = ["--boost_dir="+boostdir,
                "--arch="+arch,
                "--prefix="+prefix,
                ndkdir]

  command = "./build-android.sh %s" % ' '.join(args_array)
  run([command])

if __name__ == "__main__":
  parser = argparse.ArgumentParser()
  parser.add_argument('-d','--boost_dir')
  parser.add_argument('-a','--arch')
  parser.add_argument('-o','--outputdir')
  parser.add_argument('-n','--ndkdir')
  parser.add_argument('-m','--msysdir', default=None)
  args = parser.parse_args()
  print("prefix %s"%args.outputdir)

  platform = os.name
  if platform is 'posix':
    build_for_posix(args.boost_dir, args.arch, args.outputdir, args.ndkdir)
  elif platform is 'nt':
    build_for_msys(args.msysdir, args.boost_dir, args.arch, args.outputdir, args.ndkdir)