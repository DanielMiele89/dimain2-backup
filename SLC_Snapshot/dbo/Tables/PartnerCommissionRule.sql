CREATE TABLE [dbo].[PartnerCommissionRule] (
    [ID]                                INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PartnerID]                         INT           NOT NULL,
    [TypeID]                            INT           NOT NULL,
    [CommissionRate]                    FLOAT (53)    NOT NULL,
    [Status]                            BIT           NOT NULL,
    [Priority]                          INT           NULL,
    [CreationDate]                      DATETIME      NOT NULL,
    [CreationStaffID]                   INT           NOT NULL,
    [DeletionDate]                      DATETIME      NULL,
    [DeletionStaffID]                   INT           NULL,
    [MaximumUsesPerFan]                 INT           NULL,
    [StartDate]                         DATETIME      NULL,
    [EndDate]                           DATETIME      NULL,
    [RequiredNumberOfPriorTransactions] INT           NULL,
    [RequiredMinimumBasketSize]         SMALLMONEY    NULL,
    [RequiredMaximumBasketSize]         SMALLMONEY    NULL,
    [RequiredChannel]                   TINYINT       NULL,
    [RequiredBinRange]                  NVARCHAR (6)  NULL,
    [RequiredClubID]                    INT           NULL,
    [RequiredMinimumHourOfDay]          TINYINT       NULL,
    [RequiredMaximumHourOfDay]          TINYINT       NULL,
    [RequiredMerchantID]                NVARCHAR (20) NULL,
    [RequiredIronOfferID]               INT           NULL,
    [RequiredRetailOutletID]            INT           NULL,
    [RequiredCardholderPresence]        TINYINT       NULL,
    [CommissionAmount]                  SMALLMONEY    NULL,
    [CommissionLimit]                   SMALLMONEY    NULL,
    CONSTRAINT [PK_PartnerCommissionRule] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[PartnerCommissionRule] TO [virgin_etl_user]
    AS [dbo];

