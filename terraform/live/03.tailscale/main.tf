resource "tailscale_acl" "main" {
  acl = jsonencode({
    tagOwners = {
      "tag:k8s-operator" = []
      "tag:k8s"          = ["tag:k8s-operator"]
    }

    grants = [
      {
        src = ["*"]
        dst = ["*"]
        ip  = ["*"]
      },
      {
        src = ["*"]
        dst = ["tag:k8s"]
        ip  = ["*"]
      }
    ]

    ssh = [
      {
        "action" = "check"
        "src"    = ["autogroup:member"]
        "dst"    = ["autogroup:self"]
        "users"  = ["autogroup:nonroot", "root"]
      }
    ]

    autoApprovers = {
      services = {
        "tag:k8s" = ["tag:k8s"]
      }
    }
  })

}
