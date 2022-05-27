CREATE TABLE [Staging].[CustomerPartner_ExclusionsRules] (
    [ID]                       INT     IDENTITY (1, 1) NOT NULL,
    [PartnerID]                INT     NULL,
    [StartDate]                DATE    NULL,
    [EndDate]                  DATE    NULL,
    [PaymentMethodAvailableID] TINYINT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [idx_CustomerPartner_Exclusions_SD]
    ON [Staging].[CustomerPartner_ExclusionsRules]([PartnerID] ASC, [StartDate] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_CustomerPartner_Exclusions_ED]
    ON [Staging].[CustomerPartner_ExclusionsRules]([PartnerID] ASC, [EndDate] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_CustomerPartner_Exclusions_SDED]
    ON [Staging].[CustomerPartner_ExclusionsRules]([PartnerID] ASC, [StartDate] ASC, [EndDate] ASC);

