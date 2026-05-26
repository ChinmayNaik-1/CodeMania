import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { dbPool } from '../index.js';
import * as contestService from '../services/contestService.js';
import * as icpcService from '../services/icpcService.js';

const router = Router();

router.use(authMiddleware);

router.get('/invites/pending', async (req, res) => {
  try {
    const invites = await contestService.getMyInvites(req.user.id);
    return res.json({ invites });
  } catch (error) {
    console.error('Get invites error:', error);
    return res.status(500).json({ error: 'Failed to fetch invites' });
  }
});

router.get('/', async (req, res) => {
  try {
    const contests = await contestService.getContests();
    res.json(contests);
  } catch (error) {
    console.error('Get contests error:', error);
    res.status(500).json({ error: 'Failed to fetch contests' });
  }
});

router.get('/:contestId', async (req, res) => {
  try {
    const contestId = parseInt(req.params.contestId, 10);
    if (Number.isNaN(contestId)) {
      return res.status(400).json({ error: 'Invalid contest id' });
    }

    const data = await contestService.getContestById(contestId);
    return res.json(data);
  } catch (error) {
    const status = error.status || 500;
    const message = error.status ? error.message : 'Failed to fetch contest';
    console.error('Get contest error:', error);
    return res.status(status).json({ error: message });
  }
});

router.get('/:contestId/leaderboard', async (req, res) => {
  try {
    const contestId = parseInt(req.params.contestId, 10);
    if (Number.isNaN(contestId)) {
      return res.status(400).json({ error: 'Invalid contest id' });
    }

    const leaderboard = await icpcService.getLeaderboard(contestId);
    return res.json({ leaderboard });
  } catch (error) {
    console.error('Get leaderboard error:', error);
    return res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
});

router.get('/:contestId/my-team', async (req, res) => {
  try {
    const contestId = parseInt(req.params.contestId, 10);
    if (Number.isNaN(contestId)) {
      return res.status(400).json({ error: 'Invalid contest id' });
    }

    const team = await contestService.getMyTeam(contestId, req.user.id);
    return res.json({ team });
  } catch (error) {
    const status = error.status || 500;
    const message = error.status ? error.message : 'Failed to fetch team';
    console.error('Get my team error:', error);
    return res.status(status).json({ error: message });
  }
});

router.post('/:contestId/teams', async (req, res) => {
  try {
    const contestId = parseInt(req.params.contestId, 10);
    const { teamName } = req.body;

    if (Number.isNaN(contestId)) {
      return res.status(400).json({ error: 'Invalid contest id' });
    }

    const team = await contestService.createTeam(contestId, req.user.id, teamName);
    return res.status(201).json({ team });
  } catch (error) {
    const status = error.status || 500;
    const message = error.status ? error.message : 'Failed to create team';
    console.error('Create team error:', error);
    return res.status(status).json({ error: message });
  }
});

router.post('/teams/:teamId/invite', async (req, res) => {
  try {
    const teamId = parseInt(req.params.teamId, 10);
    let inviteeId = req.body.inviteeId !== undefined
      ? parseInt(req.body.inviteeId, 10)
      : NaN;
    const inviteeUsername = typeof req.body.inviteeUsername === 'string'
      ? req.body.inviteeUsername.trim()
      : '';

    if (Number.isNaN(teamId)) {
      return res.status(400).json({ error: 'Invalid team id' });
    }

    if (Number.isNaN(inviteeId) && inviteeUsername) {
      const userResult = await dbPool.query(
        'SELECT id FROM users WHERE username = $1 LIMIT 1',
        [inviteeUsername]
      );
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      inviteeId = userResult.rows[0].id;
    }

    if (Number.isNaN(inviteeId)) {
      return res.status(400).json({ error: 'inviteeId or inviteeUsername is required' });
    }

    const invite = await contestService.inviteToTeam(teamId, inviteeId, req.user.id);
    return res.status(201).json({ invite });
  } catch (error) {
    const status = error.status || 500;
    const message = error.status ? error.message : 'Failed to invite user';
    console.error('Invite error:', error);
    return res.status(status).json({ error: message });
  }
});

router.post('/invites/:inviteId/respond', async (req, res) => {
  try {
    const inviteId = parseInt(req.params.inviteId, 10);
    const { accept } = req.body;

    if (Number.isNaN(inviteId)) {
      return res.status(400).json({ error: 'Invalid invite id' });
    }

    if (typeof accept !== 'boolean') {
      return res.status(400).json({ error: 'accept must be a boolean' });
    }

    const result = await contestService.respondToInvite(inviteId, req.user.id, accept);
    return res.json(result);
  } catch (error) {
    const status = error.status || 500;
    const message = error.status ? error.message : 'Failed to respond to invite';
    console.error('Respond invite error:', error);
    return res.status(status).json({ error: message });
  }
});

export default router;
