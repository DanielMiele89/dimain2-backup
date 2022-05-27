CREATE TABLE [Relational].[MRF_ShopperSegmentDetails] (
    [PartnerID]            SMALLINT       NOT NULL,
    [SS_AcquireLength]     SMALLINT       NULL,
    [SS_LapsersDefinition] SMALLINT       NULL,
    [SS_WelcomeEmail]      SMALLINT       NULL,
    [SS_Acq_Split]         DECIMAL (3, 2) DEFAULT ((0.5)) NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC)
);

