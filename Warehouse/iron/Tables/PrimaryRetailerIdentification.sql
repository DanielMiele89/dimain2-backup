CREATE TABLE [iron].[PrimaryRetailerIdentification] (
    [PartnerID]        INT NOT NULL,
    [PrimaryPartnerID] INT NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC),
    CONSTRAINT [ucPrimaryRetailerIdentication] UNIQUE NONCLUSTERED ([PartnerID] ASC, [PrimaryPartnerID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[iron].[PrimaryRetailerIdentification] TO [crtimport]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[iron].[PrimaryRetailerIdentification] TO [gas]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[iron].[PrimaryRetailerIdentification] TO [Analytics]
    AS [dbo];

