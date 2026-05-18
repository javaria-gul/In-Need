import {
  Controller, Post, Get, Param, Body, UseGuards,
  Request, ParseIntPipe, UseInterceptors, UploadedFiles, BadRequestException,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { ReviewsService, CreateReviewDto } from './reviews.service.js';
import { CloudinaryService } from '../cloudinary/cloudinary.service.js';

@ApiTags('reviews')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('reviews')
export class ReviewsController {
  constructor(
    private readonly svc: ReviewsService,
    private readonly cloudinaryService: CloudinaryService,
  ) {}

  @Post()
  @UseInterceptors(
    FileFieldsInterceptor(
      [
        { name: 'beforeImage', maxCount: 1 },
        { name: 'afterImage', maxCount: 1 },
      ],
      { storage: memoryStorage() },
    ),
  )
  async submit(
    @Request() req: any,
    @Body() dto: CreateReviewDto,
    @UploadedFiles()
    files: {
      beforeImage?: Express.Multer.File[];
      afterImage?: Express.Multer.File[];
    },
  ) {
    const beforeFile = files.beforeImage?.[0];
    const afterFile = files.afterImage?.[0];

    if (!beforeFile || !afterFile) {
      throw new BadRequestException('Before and after images are required');
    }

    const [beforeImageUrl, afterImageUrl] = await Promise.all([
      this.cloudinaryService.uploadImage(beforeFile),
      this.cloudinaryService.uploadImage(afterFile),
    ]);

    return this.svc.submitReview(
      req.user.userId,
      dto,
      beforeImageUrl,
      afterImageUrl,
    );
  }

  @Get('check/:jobId')
  check(
    @Request() req: any,
    @Param('jobId', ParseIntPipe) jobId: number,
  ) {
    return this.svc.hasReviewed(req.user.userId, jobId);
  }

  @Get('user/:userId')
  forUser(@Param('userId', ParseIntPipe) userId: number) {
    return this.svc.getReviewsForUser(userId);
  }

  @Get('verify/:reviewId')
  verify(@Param('reviewId', ParseIntPipe) reviewId: number) {
    return this.svc.verifyReview(reviewId);
  }

  // 🔗 Full blockchain endpoints
  @Get('chain/verify')
  verifyFullChain() {
    return this.svc.verifyFullChain();
  }

  @Get('chain/history')
  getChainHistory() {
    return this.svc.getChainHistory();
  }
}