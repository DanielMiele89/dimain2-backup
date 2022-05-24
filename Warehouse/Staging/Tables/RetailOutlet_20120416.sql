CREATE TABLE [Staging].[RetailOutlet_20120416] (
    [ID]                     INT               IDENTITY (1, 1) NOT NULL,
    [PartnerID]              INT               NOT NULL,
    [MerchantID]             NVARCHAR (50)     NOT NULL,
    [VAT]                    INT               NOT NULL,
    [ActivationDays]         INT               NOT NULL,
    [TerminalCount]          SMALLINT          NOT NULL,
    [TerminalTypes]          NVARCHAR (100)    NOT NULL,
    [FanID]                  INT               NOT NULL,
    [SuppressFromSearch]     BIT               NOT NULL,
    [CallbackDate]           DATETIME          NULL,
    [Notes]                  NVARCHAR (1024)   NULL,
    [Functional]             BIT               NOT NULL,
    [MasterRetailOutletID]   INT               NULL,
    [Channel]                TINYINT           NOT NULL,
    [PartnerOutletReference] NVARCHAR (20)     NULL,
    [Coordinates]            [sys].[geography] NULL
);

