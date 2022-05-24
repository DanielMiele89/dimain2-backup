CREATE TABLE [Staging].[CustomerPartner_Exclusions] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [FanID]     INT  NULL,
    [PartnerID] INT  NULL,
    [StartDate] DATE NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [idx_CustomerPartner_Exclusions_all]
    ON [Staging].[CustomerPartner_Exclusions]([FanID] ASC, [PartnerID] ASC, [StartDate] ASC, [EndDate] ASC);

