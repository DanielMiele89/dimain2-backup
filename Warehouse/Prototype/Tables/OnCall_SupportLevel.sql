CREATE TABLE [Prototype].[OnCall_SupportLevel] (
    [SupportLevel]       INT          NOT NULL,
    [SupportDescription] VARCHAR (30) NOT NULL,
    [isCritical]         BIT          NOT NULL,
    CONSTRAINT [PK_OnCallSupportLevel] PRIMARY KEY CLUSTERED ([SupportLevel] ASC)
);

