CREATE TABLE [Prototype].[retailer_email_stats] (
    [partnerID]    INT        NOT NULL,
    [emaildate]    DATE       NULL,
    [Targeted]     INT        DEFAULT ((0)) NULL,
    [Openers]      INT        DEFAULT ((0)) NULL,
    [OpenRate]     FLOAT (53) DEFAULT ((0)) NULL,
    [Spenders]     INT        DEFAULT ((0)) NULL,
    [ResponseRate] FLOAT (53) DEFAULT ((0)) NULL
);

