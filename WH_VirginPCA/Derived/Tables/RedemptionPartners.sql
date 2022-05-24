CREATE TABLE [Derived].[RedemptionPartners] (
    [RedemptionPartnerGUID] UNIQUEIDENTIFIER NOT NULL,
    [PartnerName]           VARCHAR (250)    NULL,
    [PartnerType]           VARCHAR (50)     NULL
);




GO
GRANT SELECT
    ON OBJECT::[Derived].[RedemptionPartners] TO [visa_etl_user]
    AS [New_DataOps];

