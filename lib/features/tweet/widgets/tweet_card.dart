// In the user info section of the TweetCard, add the health badge:
Row(
  children: [
    Text(
      user.name,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: FontWeight.bold,
      ),
    ),
    const SizedBox(width: 4),
    if (user.isTwitterBlue)
      SvgPicture.asset(
        AssetsConstants.verifiedIcon,
        height: 16,
      ),
    const SizedBox(width: 4),
    SvgPicture.asset(
      user.getBadgeAsset(),
      height: 18,
      width: 18,
    ),
  ],
),