//
//  MIKMIDIPlayer.m
//  MIKMIDI
//
//  Created by Chris Flesner on 9/8/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIPlayer.h"


@interface MIKMIDIPlayer ()

@property (nonatomic) MusicPlayer musicPlayer;
@property (nonatomic) BOOL isPlaying;

@property (strong, nonatomic) NSNumber *lastStoppedAtTimeStampNumber;

@property (strong, nonatomic) NSDate *lastPlaybackStartedTime;

@end


@implementation MIKMIDIPlayer

#pragma mark - Lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        MusicPlayer musicPlayer;
        OSStatus err = NewMusicPlayer(&musicPlayer);
        if (err) {
            NSLog(@"NewMusicPlayer() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
            return nil;
        }

        self.musicPlayer = musicPlayer;
        self.loopStop = kMusicTimeStamp_EndOfTrack;
    }
    return self;
}

- (void)dealloc
{
    if (self.isPlaying) [self stopPlayback];

    OSStatus err = DisposeMusicPlayer(_musicPlayer);
    if (err) NSLog(@"DisposeMusicPlayer() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
}

#pragma mark - Playback

- (void)preparePlayback
{
    OSStatus err = MusicPlayerPreroll(self.musicPlayer);
    if (err) NSLog(@"MusicPlayerPreroll() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
}

- (void)startPlayback
{
    [self startPlaybackFromPosition:0];
}

- (void)startPlaybackFromPosition:(MusicTimeStamp)position
{
    if (self.isPlaying) [self stopPlayback];

    [self loopTracksWhenNeeded];

    OSStatus err = MusicPlayerSetTime(self.musicPlayer, position);
    if (err) return NSLog(@"MusicPlayerSetTime() failed with error %d in %s.", err, __PRETTY_FUNCTION__);

    Float64 sequenceDuration = self.sequence.durationInSeconds;
    Float64 positionInTime;

    err = MusicSequenceGetSecondsForBeats(self.sequence.musicSequence, position, &positionInTime);
    if (err) return NSLog(@"MusicSequenceGetSecondsForBeats() failed with error %d in %s.", err, __PRETTY_FUNCTION__);

    Float64 playbackDuration = (sequenceDuration - positionInTime) + self.tailDuration;

    err = MusicPlayerStart(self.musicPlayer);
    if (err) return NSLog(@"MusicPlayerStart() failed with error %d in %s.", err, __PRETTY_FUNCTION__);

    self.isPlaying = YES;
    NSDate *startTime = self.lastPlaybackStartedTime;
    self.lastPlaybackStartedTime = startTime;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(playbackDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([startTime isEqualToDate:self.lastPlaybackStartedTime]) {
            if (!self.isLooping) {
                [self stopPlayback];
            }
        }
    });
}

- (void)resumePlayback
{
    if (!self.lastStoppedAtTimeStampNumber) return [self startPlayback];

    MusicTimeStamp length = self.sequence.length;
    MusicTimeStamp lastTimeStamp = [self.lastStoppedAtTimeStampNumber doubleValue];

    if (lastTimeStamp > length) {
        NSInteger numTimesLooped = lastTimeStamp / length;
        lastTimeStamp -= (length * numTimesLooped);
    }

    [self startPlaybackFromPosition:lastTimeStamp];
}

- (void)stopPlayback
{
    if (!self.isPlaying) return;

    Boolean musicPlayerIsPlaying = TRUE;
    OSStatus err = MusicPlayerIsPlaying(self.musicPlayer, &musicPlayerIsPlaying);
    if (err) {
        NSLog(@"MusicPlayerIsPlaying() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    }

    self.lastStoppedAtTimeStampNumber = @(self.currentTimeStamp);

    if (musicPlayerIsPlaying) {
        err = MusicPlayerStop(self.musicPlayer);
        if (err) {
            NSLog(@"MusicPlayerStop() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
        }
    }

    err = MusicPlayerSetSequence(self.musicPlayer, NULL);
    if (err) {
        NSLog(@"MusicPlayerSetSequence() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
        return;
    }

    self.isPlaying = NO;
}

#pragma mark - Looping

- (void)loopTracksWhenNeeded
{
    NSLog(@"%s is not yet implemented.", __PRETTY_FUNCTION__);
}

#pragma mark - Properties

- (void)setSequence:(MIKMIDISequence *)sequence
{
    if (_sequence == sequence) return;

    MusicSequence musicSequence = sequence.musicSequence;
    OSStatus err = MusicPlayerSetSequence(self.musicPlayer, musicSequence);
    if (err) return NSLog(@"MusicPlayerSetSequence() failed with error %d in %s.", err, __PRETTY_FUNCTION__);

    _sequence = sequence;
}

- (MusicTimeStamp)currentTimeStamp
{
    MusicTimeStamp position = 0;
    OSStatus err = MusicPlayerGetTime(self.musicPlayer, &position);
    if (err) NSLog(@"MusicPlayerGetTime() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return position;
}

- (void)setCurrentTimeStamp:(MusicTimeStamp)currentTimeStamp
{
    OSStatus err = MusicPlayerSetTime(self.musicPlayer, currentTimeStamp);
    if (err) NSLog(@"MusicPlayerSetTime() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
}

- (Float64)playRateScaler
{
    NSLog(@"%s is not yet implemented.", __PRETTY_FUNCTION__);
    return 0;
}

- (void)setPlayRateScaler:(Float64)playRateScaler
{
    NSLog(@"%s is not yet implemented.", __PRETTY_FUNCTION__);
}

@end