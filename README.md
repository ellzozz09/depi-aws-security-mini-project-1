# Secure-AWS-Web-Platform
Secure AWS Web Platform built with Terraform featuring private networking, CloudFront, ALB, EC2, RDS, EFS, monitoring, automated security remediation, backup protection, and IaC best practices

# IAM & Security Identities

| Identity / Component | Resource Type | What It Can Do | Why (Security Rationale) |
| :--- | :--- | :--- | :--- |
| **`depi-sec-developers`** | IAM Group | Inherits `ReadOnlyAccess` AWS Managed Policy across all services. | Enforces central group-based access management and the Principle of Least Privilege for developers, preventing unintended infrastructure modifications. |
| **`depi-dev-1`** | IAM User | Authenticates to the AWS Management Console with forced password reset on first sign-in; inherits read-only access via `depi-sec-developers`. | Assigns individual accountability for human access without issuing long-lived access keys or elevated administrative privileges. |
| **`depi-sec-ec2-role`** | IAM Role | Assumed by the EC2 service (`ec2.amazonaws.com`); attached to `AmazonSSMManagedInstanceCore` and `depi-sec-s3-app-read`. | Provides temporary credentials via AWS Security Token Service (STS) to the workload, removing the need to embed static AWS access keys on virtual server file systems. Enables secure shell access via Systems Manager (SSM) without open SSH ports. |
| **`depi-sec-ec2-role` (Profile)** | Instance Profile | Acts as the structural container that attaches `depi-sec-ec2-role` to EC2 instances. | Required by EC2 hardware to securely pass temporary IAM role credentials directly to the instance metadata service . |