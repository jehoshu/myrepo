include "root" {
    path = find_in_parent_folders()
}

include "envcommon" {
    path = "${dirname(find_in_parent_folders())}/_envcommon/aws-vpc-tagging.hcl"
}

locals {}

inputs = {

}