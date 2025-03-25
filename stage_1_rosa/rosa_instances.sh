aws ec2 describe-instance-types --output json | \
jq -r '.InstanceTypes[] | [.InstanceType, 
      (if (.InstanceType | test("g|p")) then "accelerated_computing"
      elif (.InstanceType | test("^t")) then "burstable" 
      elif (.InstanceType | test("^c")) then "compute_optimized"
      elif (.InstanceType | test("^r|^x|^z")) then "memory_optimized"
      elif (.InstanceType | test("^m")) then "general_purpose"
      else "storage_optimized" end),
      .VCpuInfo.DefaultVCpus, 
      (.MemoryInfo.SizeInMiB/1024 | tostring) + " GiB"] | @tsv' | \
sort | \
awk 'BEGIN {printf "%-18s %-21s %-10s %s\n", "ID", "CATEGORY", "CPU_CORES", "MEMORY"} 
  {printf "%-18s %-21s %-10s %s\n", $1, $2, $3, $4}'