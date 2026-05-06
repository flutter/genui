// ignore_for_file: avoid_print

import 'dart:io';

// Images for climbing locations.
final imageUrls = <String>[
  'https://fastly.picsum.photos/id/10/2500/1667.jpg?hmac=J04WWC_ebchx3WwzbM-Z4_KC_LeLBWr5LZMaAkWkF68',
  'https://fastly.picsum.photos/id/15/2500/1667.jpg?hmac=Lv03D1Y3AsZ9L2tMMC1KQZekBVaQSDc1waqJ54IHvo4',
  'https://fastly.picsum.photos/id/29/4000/2670.jpg?hmac=rCbRAl24FzrSzwlR5tL-Aqzyu5tX_PA95VJtnUXegGU',
  'https://fastly.picsum.photos/id/28/4928/3264.jpg?hmac=GnYF-RnBUg44PFfU5pcw_Qs0ReOyStdnZ8MtQWJqTfA',
  'https://fastly.picsum.photos/id/46/3264/2448.jpg?hmac=ZHE8nk-Q9uRp4MxgKNvN7V7pYFvA-9BCv99ltY3HBv4',
  'https://fastly.picsum.photos/id/62/2000/1333.jpg?hmac=PbFIn8k0AndjiUwpOJcfHz2h-wPCQi_vJRTJZPdr6kQ',
  'https://fastly.picsum.photos/id/67/2848/4288.jpg?hmac=X_Z0Wdd3HiJ8eWT0ohdmpRSIA6e6s265INUMuHA8MqA',
  'https://fastly.picsum.photos/id/66/3264/2448.jpg?hmac=H9yvGug9-Lk5f-1qZqs6dEV-Yd40jFOIC7oudo4eBK4',
  'https://fastly.picsum.photos/id/79/2000/3011.jpg?hmac=TQsXWj0kLBLRXbSAh2Pygog1-cOefqpjEoKyl0uD3tg',
  'https://fastly.picsum.photos/id/121/1600/1067.jpg?hmac=QDrnlQAvC_54xDpx2afpzKMbjCZvnRljseYvkK8XPCQ',
  'https://fastly.picsum.photos/id/128/3823/2549.jpg?hmac=VbPyA2vESva2YdoXqll9REBcbQIskgv_c-D60C1s0xc',
  'https://fastly.picsum.photos/id/134/4928/3264.jpg?hmac=IcPmWTNClVqLcr7PpqBrfOAvgmJbqw0Z8jZvmsCrC-c',
  'https://fastly.picsum.photos/id/136/4032/2272.jpg?hmac=8ygXp61m49P3x_uMkBih2sZHJwEaTLp5ZuOOVNE9qhU',
  'https://fastly.picsum.photos/id/166/1280/720.jpg?hmac=w7NFsk0bL2IjWSdLJy0Ymow0MFw6n2BCjPYhJCgEjXs',
  'https://fastly.picsum.photos/id/177/2515/1830.jpg?hmac=G8-2Q3-YPB2TreOK-4ofcmS-z5F6chIA0GHYAe5yzDY',
  'https://fastly.picsum.photos/id/184/4288/2848.jpg?hmac=l0fKWzmWf6ISTPMEm1WjRdxn35sg6U3GwZLn5lvKhTI',
  'https://fastly.picsum.photos/id/191/2560/1707.jpg?hmac=60dSBXsS8n-Gi2-LMtm-BfDd6Mz_JMrYI8jN4yb41qg',
  'https://fastly.picsum.photos/id/231/4088/2715.jpg?hmac=PxhkmiNJrVS5AgI8U-r_IsWSN5a7cTjpjIbvmtpLMDI',
  'https://fastly.picsum.photos/id/235/5000/3333.jpg?hmac=i9YaRj_AF62lGVYNlYhdL2gqRDxoUzypXLUXBj8ihCc',
  'https://fastly.picsum.photos/id/243/2300/1533.jpg?hmac=BnvN5jcWjSaFHq5vJoJjJltaTOWalVdYo2iR6-s03bI',
  'https://fastly.picsum.photos/id/247/3264/2168.jpg?hmac=mNHRvpzD7DJ1ZsJLM623LUPYrecz33Q6H5JscVt66IU',
  'https://fastly.picsum.photos/id/287/4288/2848.jpg?hmac=f_-W7-bOKUxLoH9uOz4Hwk9D8zYTgzbHX7i_vY_ljug',
  'https://fastly.picsum.photos/id/296/3072/2048.jpg?hmac=2rqN1no5ACOxtJEFbRyRbcq2DgDrytXoDIx2CulBhHM',
  'https://fastly.picsum.photos/id/315/2100/1500.jpg?hmac=-04N-t7k_WwNeI30ryvWT4KGzy7XVdsw41fNRDFizck',
  'https://fastly.picsum.photos/id/343/2304/1536.jpg?hmac=3NDuNow_H5cP8si2ejcQrSGeHCwKclLm-RUeOXnn88Q',
  'https://fastly.picsum.photos/id/368/4896/3264.jpg?hmac=fmSrJGF46XETC-2mpgtt5kXEx5HXdnFy2kI-Wh0AsRE',
  'https://fastly.picsum.photos/id/368/4896/3264.jpg?hmac=fmSrJGF46XETC-2mpgtt5kXEx5HXdnFy2kI-Wh0AsRE',
  'https://fastly.picsum.photos/id/377/4884/3256.jpg?hmac=OLVw864UkoqYrrRmC1Xh5-5DtczeP7iEZKMlv1YLwac',
  'https://fastly.picsum.photos/id/450/4288/2848.jpg?hmac=z5F4ae5WsMGGD0g8pfAXTRkiO5xI_KLb2jH5zP-w_rs',
  'https://fastly.picsum.photos/id/472/5000/3333.jpg?hmac=t1JUSVsv6_Uhp-gADhP1IT7RU21RVK1DeZC1C7FRTak',
  'https://fastly.picsum.photos/id/475/4288/2848.jpg?hmac=04kbAs78mTA8qt-g4RoGd_oI6Qzc-4WmvqBQ6fjcR0s',
  'https://fastly.picsum.photos/id/485/4084/2713.jpg?hmac=0sOzT0bz7obp9s001Ng-dEDxJh9oVAnyWELkL9BG1U8',
];

void main() async {
  final urls = imageUrls;
  final regExp = RegExp(
    r'https://fastly\.picsum\.photos/id/(\d+)/(\d+)/(\d+)\.jpg\?hmac=.*',
  );
  print('Found ${urls.length} image URLs.');

  final dir = Directory('assets/climbing');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
    print('Created directory assets/climbing');
  }

  final client = HttpClient();

  for (final url in urls) {
    final match = regExp.firstMatch(url);
    if (match == null) continue;

    final id = match.group(1);
    final width = match.group(2);
    final height = match.group(3);
    final filename = '${id}x${width}x$height.jpg';
    final filePath = 'assets/climbing/$filename';

    final targetFile = File(filePath);
    if (await targetFile.exists()) {
      print('File $filename already exists, skipping.');
      continue;
    }

    print('Downloading $url to $filePath ...');
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final fileStream = targetFile.openWrite();
        await response.pipe(fileStream);
        print('Downloaded $filename');
      } else {
        print('Failed to download $url: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading $url: $e');
    }
  }

  client.close();
  print('Done.');
}
