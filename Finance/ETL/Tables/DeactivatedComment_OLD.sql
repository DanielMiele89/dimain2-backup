CREATE TABLE [ETL].[DeactivatedComment_OLD] (
    [DeactivatedCommentID] INT          IDENTITY (1, 1) NOT NULL,
    [LikeString]           VARCHAR (30) NOT NULL,
    [LikePriority]         INT          NOT NULL,
    CONSTRAINT [PK_DeactivatedCommentID_OLD] PRIMARY KEY CLUSTERED ([DeactivatedCommentID] ASC)
);

