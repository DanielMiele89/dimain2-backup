CREATE TABLE [dbo].[DirectDebitOfferRules] (
    [ID]             INT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [IronOfferID]    INT        NOT NULL,
    [MinimumSpend]   SMALLMONEY NULL,
    [FixedReward]    BIT        NULL,
    [RewardAmount]   SMALLMONEY NULL,
    [RewardPercent]  FLOAT (53) NULL,
    [BillingAmount]  SMALLMONEY NULL,
    [BillingPercent] FLOAT (53) NULL,
    CONSTRAINT [PK_DirectDebitOfferRules] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[DirectDebitOfferRules] TO [virgin_etl_user]
    AS [dbo];

