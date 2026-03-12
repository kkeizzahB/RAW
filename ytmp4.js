

const axios = require('axios');
const fs = require('fs');

const quality = {
  '1080p': 'Full HD (1080p)',
  '720p': 'HD (720p)',
  '480p': 'SD (480p)',
  '360p': 'Low (360p)',
  '240p': 'Very Low (240p)',
  '144p': 'Tiny (144p)'
};

async function getVideoInfo(url) {
  const { data } = await axios.post(`https://api.ytmp4.fit/api/video-info`, { url }, {
    headers: {
      'Content-Type': 'application/json',
      'Origin': 'https://ytmp4.fit',
      'Referer': 'https://ytmp4.fit/'
    }
  });

  if (!data || !data.title) throw new Error('gagal ambil info.');
  return data;
}

async function downloadVideo(url, quality) {
  const res = await axios.post(`https://api.ytmp4.fit/api/download`, { url, quality }, {
    responseType: 'arraybuffer',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/octet-stream',
      'Origin': 'https://ytmp4.fit',
      'Referer': 'https://ytmp4.fit/',
    }
  });

  if (!res.headers['content-type'].includes('video')) {
    throw new Error('gagal.');
  }

  const filename = decodeURIComponent(
    (res.headers['content-disposition'] || '').split("filename*=UTF-8''")[1] || `video_${quality}.mp4`
  ).replace(/[\/\\:*?"<>|]/g, '_');

  fs.writeFileSync(filename, res.data);
  console.log(`succes simpan di: ${filename}`);
}

// tess
const main = async () => {
  const url = 'https://youtube.com/watch?v=60ItHLz5WEA';

  try {
    const info = await getVideoInfo(url);

    console.log('Judul:', info.title);
    console.log('Channel:', info.channel);
    console.log('Durasi:', info.duration);
    console.log('Views:', info.views);
  
    const selectedQuality = '360p';
    await downloadVideo(url, selectedQuality);

  } catch (err) {
    console.error('emror:', err.message);
  }
};

main();

module.exports = {
  getVideoInfo,
  downloadVideo,
  quality
};
