CREATE TABLE [dbo].[TmpDailyMI] (
    [CUSTOMER ID]                      VARCHAR (10)  NULL,
    [E-MAIL ADDRESS]                   VARCHAR (255) NULL,
    [MOBILE NUMBER]                    VARCHAR (20)  NULL,
    [BANK ID]                          VARCHAR (4)   NULL,
    [IS MARKETING SUPPRESSED SMS]      CHAR (1)      NULL,
    [IS MARKETING SUPPRESSED Email]    CHAR (1)      NULL,
    [IS MARKETING SUPPRESSED DM]       CHAR (1)      NULL,
    [IS CONTROL]                       CHAR (1)      NULL,
    [LAUNCH DATE]                      DATE          NULL,
    [OPTED OUT]                        CHAR (1)      NULL,
    [OPTED OUT DATE]                   DATE          NULL,
    [ACTIVATED]                        CHAR (1)      NULL,
    [ACTIVATION CHANNEL]               TINYINT       NULL,
    [ACTIVATED DATE]                   DATE          NULL,
    [ACTIVATED OFFLINE]                CHAR (1)      NULL,
    [TOTAL TRANSACTION AMOUNT]         MONEY         NULL,
    [TOTAL TRANSACTION COUNT]          INT           NULL,
    [TOTAL CASHBACK BALANCE - PENDING] MONEY         NULL,
    [TOTAL CASHBACK BALANCE – CLEARED] MONEY         NULL,
    [TOTAL REDEEMED VALUE]             MONEY         NULL,
    [REDEEMED VALUE IN CASH]           MONEY         NULL,
    [REDEEMED VALUE IN TRADEUP]        MONEY         NULL,
    [REDEEMED VALUE IN CHARITY]        MONEY         NULL,
    [CONTACT HISTORY]                  INT           NULL
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[TmpDailyMI] TO [crtimport]
    AS [dbo];

