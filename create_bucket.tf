# Criação de um bucket S3 - Desafio Técnico - datacosmos
resource "aws_s3_bucket" "meu_bucket" {
  bucket = "grupo01-bucket-cloud" # Nome único e válido do bucket
  acl    = "private"              # Define o acesso como privado

  versioning {
    enabled = true                # Habilitar versionamento
  }

  lifecycle_rule {
    id      = "log-expiration"
    enabled = true

    expiration {
      days = 90 # Logs antigos serão excluídos após 90 dias
    }
  }

  tags = {
    Name        = "Meu Bucket S3"
    Environment = "Dev"
    Owner       = "grupo01"
    ManagedBy   = "Terraform"
  }
}

# Política de bloqueio de acesso público
resource "aws_s3_bucket_public_access_block" "meu_bucket_block" {
  bucket = aws_s3_bucket.meu_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket.meu_bucket]
}

# Criptografia padrão
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.meu_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

  depends_on = [aws_s3_bucket.meu_bucket]
}

# Logging para outro bucket (caso necessário)
resource "aws_s3_bucket" "logs_bucket" {
  bucket = "grupo01-logs-bucket"
  acl    = "private"

  tags = {
    Name = "Logs Bucket"
  }
}

resource "aws_s3_bucket_logging" "bucket_logs" {
  bucket        = aws_s3_bucket.meu_bucket.id
  target_bucket = aws_s3_bucket.logs_bucket.id # Redireciona logs para outro bucket
  target_prefix = "logs/" # Prefixo para onde os logs serão armazenados

  depends_on = [aws_s3_bucket.logs_bucket]
}
