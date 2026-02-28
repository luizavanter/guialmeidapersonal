defmodule GaPersonal.Repo.Migrations.AddAsaasFields do
  use Ecto.Migration

  def change do
    alter table(:student_profiles) do
      add :asaas_customer_id, :string
      add :cpf, :string
    end

    create index(:student_profiles, [:asaas_customer_id], unique: true)

    alter table(:payments) do
      add :asaas_charge_id, :string
      add :asaas_invoice_url, :string
      add :asaas_pix_qr_code, :text
      add :asaas_pix_payload, :text
      add :asaas_bankslip_url, :string
    end

    create index(:payments, [:asaas_charge_id], unique: true)
  end
end
