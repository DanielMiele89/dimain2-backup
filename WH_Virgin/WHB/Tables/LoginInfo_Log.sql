CREATE TABLE [WHB].[LoginInfo_Log] (
    [MsgID]           INT           IDENTITY (1, 1) NOT NULL,
    [RunID]           INT           NOT NULL,
    [Msg]             VARCHAR (MAX) NULL,
    [CreatedDateTime] DATETIME2 (7) NOT NULL,
    [isError]         BIT           NOT NULL
);

