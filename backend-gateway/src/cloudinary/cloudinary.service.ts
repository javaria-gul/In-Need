import { Injectable } from '@nestjs/common';
import { v2 as cloudinary } from 'cloudinary';

@Injectable()
export class CloudinaryService {
  private configured = false;

  private ensureConfigured() {
    if (this.configured) {
      return;
    }

    const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
    const apiKey = process.env.CLOUDINARY_API_KEY;
    const apiSecret = process.env.CLOUDINARY_API_SECRET;

    if (!cloudName || !apiKey || !apiSecret) {
      throw new Error(
        'Cloudinary is not configured. Please set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET in .env',
      );
    }

    cloudinary.config({
      cloud_name: cloudName,
      api_key: apiKey,
      api_secret: apiSecret,
    });

    this.configured = true;
  }

  async uploadImage(file: Express.Multer.File): Promise<string> {
    this.ensureConfigured();

    return new Promise((resolve, reject) => {
      cloudinary.uploader.upload_stream(
        { folder: 'apka-hunar/reviews' },
        (error, result) => {
          if (error) reject(error);
          else resolve(result!.secure_url);
        },
      ).end(file.buffer);
    });
  }
}