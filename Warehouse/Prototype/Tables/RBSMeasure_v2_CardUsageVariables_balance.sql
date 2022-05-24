CREATE TABLE [Prototype].[RBSMeasure_v2_CardUsageVariables_balance] (
    [CINID]                  INT         NULL,
    [Group1]                 VARCHAR (9) NOT NULL,
    [RSpdAll]                MONEY       NULL,
    [RSpdMonth]              MONEY       NULL,
    [RTranMonth]             INT         NULL,
    [RTransAll]              INT         NULL,
    [first12]                DATE        NULL,
    [last12]                 DATE        NULL,
    [RTrans12]               INT         NULL,
    [RSpd12]                 MONEY       NULL,
    [FirstDate]              DATE        NULL,
    [LastDate]               DATE        NULL,
    [dayssince]              INT         NULL,
    [tenure]                 INT         NULL,
    [DeadCard]               INT         NOT NULL,
    [NoSpdMonth]             INT         NOT NULL,
    [FirsSpdInMonth]         INT         NOT NULL,
    [CardType]               VARCHAR (9) NOT NULL,
    [rownumber]              BIGINT      NULL,
    [NonActive_Vol_Required] FLOAT (53)  NULL,
    [Select1]                INT         NOT NULL
);

