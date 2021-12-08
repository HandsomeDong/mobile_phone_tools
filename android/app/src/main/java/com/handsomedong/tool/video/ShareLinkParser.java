package com.handsomedong.tool.video;

/**
 * 分享链接解析接口，不同的短视频平台解析需要实现这个接口
 */
public interface ShareLinkParser {
    /**
     * 匹配分享链接
     * @param shareText 分享文本，里面会包含分享链接
     * @return
     */
    String matchShareLink(String shareText);

    /**
     * 通过分享链接解析出视频的下载链接
     * @param shareLink 分享链接
     * @return
     */
    String parse(String shareLink);
}
