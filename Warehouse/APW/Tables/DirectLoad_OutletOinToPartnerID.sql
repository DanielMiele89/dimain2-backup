CREATE TABLE [APW].[DirectLoad_OutletOinToPartnerID] (
    [ID]                               INT        IDENTITY (1, 1) NOT NULL,
    [OutletID]                         INT        NULL,
    [PartnerID]                        INT        NOT NULL,
    [Channel]                          TINYINT    NOT NULL,
    [OIN]                              INT        NULL,
    [IronOfferID]                      INT        NULL,
    [DirectDebitOriginatorID]          INT        NULL,
    [StartDate]                        DATE       NULL,
    [EndDate]                          DATE       NULL,
    [DDInvestmentProportionOfCashback] FLOAT (53) NULL,
    [PartnerCommissionRuleID]          INT        NULL,
    CONSTRAINT [PK_DirectLoad_OutletOinToPartnerID] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_MapToPartnerID]
    ON [APW].[DirectLoad_OutletOinToPartnerID]([PartnerID] ASC, [IronOfferID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DirectLoad_OutletOinToPartnerID]
    ON [APW].[DirectLoad_OutletOinToPartnerID]([OutletID] ASC, [DirectDebitOriginatorID] ASC, [PartnerCommissionRuleID] ASC);

