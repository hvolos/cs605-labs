import os
import sys

def find_parts(src_base_dir):
  parts_dirs = []
  for part_dir in os.listdir(src_base_dir):
    parts_dirs.append(os.path.join(src_base_dir, part_dir))
  return sorted(parts_dirs)


def partition_parts(parts, partitions_count, partition_id):
  parts_count = len(parts)
  parts_count_per_partition = parts_count // partitions_count
  return parts[partition_id * parts_count_per_partition: (partition_id+1) * parts_count_per_partition]


def mount_partition_and_copy_parts(partition_dest_dir, parts):
  

def usage(progname):
  print("usage: {} <parts_count> <partitions_count> <partition_id> <src_base_dir> <dest_base_dir>".format(progname))
  print("")
  print("  <parts_count>\t\ttotal number of parts to divide equally among partitions")
  print("  <partitions_count>\ttotal number of partitions to divide parts into")
  print("  <partition_id>\tidentifier of the partition to divide parts for")
  print("  <src_base_dir>\tsource directory containing all the parts")
  print("  <dest_base_dir>\tdestination directory that will receive the partition directory containing the partition parts")
  return -1


def main(args):
  if len(args) != 6:
    return usage(args[0])

  parts_count = int(args[1])
  partitions_count = int(args[2])
  partition_id = int(args[3])
  src_base_dir = args[4]
  dest_base_dir = args[5]

  all_parts = find_parts(src_base_dir)
  parts_to_partition = all_parts[:parts_count]
  parts = partition_parts(parts_to_partition, partitions_count, partition_id)
  partition_dest_dir = os.path.join(dest_base_dir, "{}_{}".format(partitions_count, partition_id))
  mount_partition_and_copy_parts(partition_dest_dir, parts)

if __name__ == "__main__":
  main(sys.argv)