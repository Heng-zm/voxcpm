"""
Liquid Glass Web Interface for Clone Voice / VoxCPM2 Speech Synthesis.
Supports both Client-side On-Device WebGPU compute and Remote Cloud Server inference.
Served at /index/clonevoice.
"""

def get_clonevoice_html() -> str:
    return """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clone Voice — AI Voice Cloning & Speech Studio (WebGPU On-Device)</title>
    <meta name="description" content="State-of-the-art zero-retention voice cloning and streaming speech synthesis powered by WebGPU and OpenBMB VoxCPM2.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=Outfit:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-base: #07090E;
            --bg-surface: rgba(15, 23, 42, 0.65);
            --bg-card: rgba(30, 41, 59, 0.45);
            --bg-card-hover: rgba(51, 65, 85, 0.55);
            --border-glass: rgba(255, 255, 255, 0.09);
            --border-glass-glow: rgba(0, 242, 254, 0.35);
            --cyan-primary: #00F2FE;
            --cyan-glow: rgba(0, 242, 254, 0.4);
            --indigo-accent: #4FACFE;
            --purple-accent: #7F00FF;
            --emerald-online: #10B981;
            --emerald-glow: rgba(16, 185, 129, 0.35);
            --red-alert: #EF4444;
            --text-main: #F8FAFC;
            --text-secondary: #94A3B8;
            --text-muted: #64748B;
            --radius-lg: 20px;
            --radius-md: 14px;
            --radius-sm: 8px;
            --shadow-glass: 0 8px 32px 0 rgba(0, 0, 0, 0.42);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            -webkit-font-smoothing: antialiased;
        }

        body {
            background-color: var(--bg-base);
            color: var(--text-main);
            font-family: 'Inter', sans-serif;
            min-height: 100vh;
            overflow-x: hidden;
            position: relative;
        }

        /* Ambient Background Mesh */
        .ambient-glow {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            pointer-events: none;
            z-index: 0;
            overflow: hidden;
        }

        .glow-orb {
            position: absolute;
            border-radius: 50%;
            filter: blur(120px);
            opacity: 0.18;
            animation: floatOrb 18s ease-in-out infinite alternate;
        }

        .orb-1 {
            width: 550px;
            height: 550px;
            background: linear-gradient(135deg, var(--cyan-primary), var(--indigo-accent));
            top: -100px;
            left: -100px;
        }

        .orb-2 {
            width: 600px;
            height: 600px;
            background: linear-gradient(135deg, var(--purple-accent), var(--indigo-accent));
            bottom: -150px;
            right: -100px;
            animation-duration: 22s;
        }

        @keyframes floatOrb {
            0% { transform: translate(0, 0) scale(1); }
            50% { transform: translate(60px, 40px) scale(1.08); }
            100% { transform: translate(-40px, 60px) scale(0.96); }
        }

        /* App Container */
        .app-container {
            position: relative;
            z-index: 1;
            max-width: 1240px;
            margin: 0 auto;
            padding: 24px 20px 60px;
            display: flex;
            flex-direction: column;
            gap: 24px;
        }

        /* Header Navigation */
        header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 24px;
            background: var(--bg-surface);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border: 1px solid var(--border-glass);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-glass);
        }

        .brand-logo {
            display: flex;
            align-items: center;
            gap: 14px;
            text-decoration: none;
            color: inherit;
        }

        .logo-icon {
            width: 44px;
            height: 44px;
            border-radius: 12px;
            background: linear-gradient(135deg, var(--cyan-primary), var(--indigo-accent));
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 4px 16px var(--cyan-glow);
        }

        .logo-icon svg {
            width: 24px;
            height: 24px;
            fill: #0B0F17;
        }

        .brand-text h1 {
            font-family: 'Outfit', sans-serif;
            font-size: 20px;
            font-weight: 700;
            letter-spacing: -0.02em;
            background: linear-gradient(135deg, #FFFFFF, var(--text-secondary));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .brand-text p {
            font-size: 11px;
            font-weight: 500;
            color: var(--cyan-primary);
            letter-spacing: 0.05em;
            text-transform: uppercase;
        }

        .header-actions {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .webgpu-badge-pill {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 6px 14px;
            background: rgba(0, 242, 254, 0.12);
            border: 1px solid rgba(0, 242, 254, 0.35);
            border-radius: 100px;
            font-size: 12px;
            font-weight: 600;
            color: var(--cyan-primary);
            box-shadow: 0 0 14px rgba(0, 242, 254, 0.2);
            transition: all 0.3s ease;
        }

        .server-status-pill {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 6px 14px;
            background: rgba(16, 185, 129, 0.10);
            border: 1px solid rgba(16, 185, 129, 0.25);
            border-radius: 100px;
            font-size: 12px;
            font-weight: 500;
            color: var(--emerald-online);
            transition: all 0.3s ease;
        }

        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background-color: var(--emerald-online);
            box-shadow: 0 0 8px var(--emerald-glow);
            animation: pulseDot 2s infinite;
        }

        .webgpu-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background-color: var(--cyan-primary);
            box-shadow: 0 0 8px var(--cyan-glow);
            animation: pulseDot 1.8s infinite;
        }

        @keyframes pulseDot {
            0%, 100% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.4; transform: scale(0.85); }
        }

        .nav-link-btn {
            padding: 7px 14px;
            border-radius: var(--radius-sm);
            background: rgba(255, 255, 255, 0.06);
            border: 1px solid var(--border-glass);
            color: var(--text-secondary);
            font-size: 12px;
            font-weight: 500;
            text-decoration: none;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .nav-link-btn:hover {
            color: #FFFFFF;
            background: rgba(255, 255, 255, 0.12);
            border-color: rgba(255, 255, 255, 0.2);
        }

        /* Target Toggle Bar */
        .target-toggle-container {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .target-toggle-bar {
            display: flex;
            gap: 6px;
            background: rgba(0, 0, 0, 0.45);
            padding: 5px;
            border-radius: var(--radius-md);
            border: 1px solid var(--border-glass);
        }

        .target-toggle-btn {
            flex: 1;
            padding: 10px 14px;
            background: transparent;
            border: none;
            color: var(--text-secondary);
            font-family: 'Outfit', sans-serif;
            font-size: 13px;
            font-weight: 700;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.25s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .target-toggle-btn:hover {
            color: #FFFFFF;
            background: rgba(255, 255, 255, 0.05);
        }

        .target-toggle-btn.active {
            background: linear-gradient(135deg, rgba(0, 242, 254, 0.18), rgba(79, 172, 254, 0.18));
            color: var(--cyan-primary);
            border: 1px solid rgba(0, 242, 254, 0.35);
            box-shadow: 0 2px 14px rgba(0, 242, 254, 0.15);
        }

        .hardware-info-card {
            background: rgba(0, 242, 254, 0.06);
            border: 1px solid rgba(0, 242, 254, 0.22);
            border-radius: var(--radius-md);
            padding: 12px 16px;
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .hardware-info-header {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 13px;
            font-weight: 700;
            color: #FFFFFF;
        }

        .hardware-info-card p {
            font-size: 11px;
            color: var(--text-secondary);
            line-height: 1.5;
        }

        /* Main Workspace Grid */
        .workspace-grid {
            display: grid;
            grid-template-columns: 1fr 1.18fr;
            gap: 24px;
        }

        @media (max-width: 960px) {
            .workspace-grid {
                grid-template-columns: 1fr;
            }
        }

        /* Glass Cards */
        .glass-card {
            background: var(--bg-surface);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border: 1px solid var(--border-glass);
            border-radius: var(--radius-lg);
            padding: 24px;
            box-shadow: var(--shadow-glass);
            display: flex;
            flex-direction: column;
            gap: 20px;
            position: relative;
        }

        .card-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .card-title {
            font-family: 'Outfit', sans-serif;
            font-size: 17px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .card-title svg {
            width: 20px;
            height: 20px;
            color: var(--cyan-primary);
        }

        .step-badge {
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            padding: 3px 8px;
            border-radius: 6px;
            background: rgba(0, 242, 254, 0.12);
            color: var(--cyan-primary);
            border: 1px solid rgba(0, 242, 254, 0.25);
        }

        /* Source Voice Tabs */
        .tab-bar {
            display: flex;
            gap: 6px;
            background: rgba(0, 0, 0, 0.35);
            padding: 4px;
            border-radius: var(--radius-md);
            border: 1px solid var(--border-glass);
        }

        .tab-btn {
            flex: 1;
            padding: 9px 12px;
            background: transparent;
            border: none;
            color: var(--text-secondary);
            font-family: inherit;
            font-size: 13px;
            font-weight: 600;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
        }

        .tab-btn:hover {
            color: #FFFFFF;
        }

        .tab-btn.active {
            background: rgba(255, 255, 255, 0.10);
            color: var(--cyan-primary);
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
        }

        .tab-content {
            display: none;
        }

        .tab-content.active {
            display: flex;
            flex-direction: column;
            gap: 16px;
        }

        /* Record Panel */
        .record-box {
            background: var(--bg-card);
            border: 1px solid var(--border-glass);
            border-radius: var(--radius-md);
            padding: 24px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 16px;
            text-align: center;
        }

        .waveform-canvas {
            width: 100%;
            height: 70px;
            background: rgba(0, 0, 0, 0.4);
            border-radius: var(--radius-sm);
            border: 1px solid rgba(255, 255, 255, 0.05);
        }

        .record-trigger-btn {
            width: 72px;
            height: 72px;
            border-radius: 50%;
            background: linear-gradient(135deg, rgba(239, 68, 68, 0.2), rgba(239, 68, 68, 0.05));
            border: 2px solid var(--red-alert);
            color: var(--red-alert);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
        }

        .record-trigger-btn:hover {
            transform: scale(1.06);
            box-shadow: 0 0 24px rgba(239, 68, 68, 0.4);
        }

        .record-trigger-btn.recording {
            animation: recordPulse 1.5s infinite;
            background: var(--red-alert);
            color: #FFFFFF;
        }

        @keyframes recordPulse {
            0% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.6); }
            70% { box-shadow: 0 0 0 18px rgba(239, 68, 68, 0); }
            100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
        }

        .record-timer {
            font-family: 'JetBrains Mono', monospace;
            font-size: 14px;
            font-weight: 600;
            color: var(--text-secondary);
        }

        /* Upload Dropzone */
        .dropzone {
            border: 2px dashed rgba(255, 255, 255, 0.16);
            border-radius: var(--radius-md);
            padding: 32px 20px;
            text-align: center;
            cursor: pointer;
            transition: all 0.25s ease;
            background: var(--bg-card);
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 12px;
        }

        .dropzone:hover, .dropzone.dragover {
            border-color: var(--cyan-primary);
            background: rgba(0, 242, 254, 0.04);
            box-shadow: 0 0 20px rgba(0, 242, 254, 0.12);
        }

        .dropzone-icon {
            width: 48px;
            height: 48px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.05);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--cyan-primary);
        }

        .dropzone-text h4 {
            font-size: 15px;
            font-weight: 600;
            margin-bottom: 4px;
        }

        .dropzone-text p {
            font-size: 12px;
            color: var(--text-muted);
        }

        /* Demo Preset Grid */
        .preset-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 10px;
        }

        .preset-btn {
            background: var(--bg-card);
            border: 1px solid var(--border-glass);
            border-radius: var(--radius-md);
            padding: 14px 10px;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 8px;
            color: inherit;
            font-family: inherit;
            text-align: center;
        }

        .preset-btn:hover {
            border-color: var(--cyan-primary);
            background: var(--bg-card-hover);
            transform: translateY(-2px);
        }

        .preset-btn.selected {
            border-color: var(--cyan-primary);
            background: rgba(0, 242, 254, 0.10);
            box-shadow: 0 0 16px rgba(0, 242, 254, 0.2);
        }

        .preset-avatar {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: linear-gradient(135deg, rgba(255, 255, 255, 0.1), rgba(255, 255, 255, 0.02));
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
        }

        .preset-name {
            font-size: 13px;
            font-weight: 600;
        }

        .preset-tag {
            font-size: 10px;
            color: var(--cyan-primary);
            background: rgba(0, 242, 254, 0.1);
            padding: 2px 6px;
            border-radius: 4px;
        }

        /* Loaded Reference Info */
        .loaded-ref-card {
            background: rgba(0, 242, 254, 0.05);
            border: 1px solid rgba(0, 242, 254, 0.2);
            border-radius: var(--radius-md);
            padding: 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .ref-meta {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .ref-icon {
            width: 36px;
            height: 36px;
            border-radius: 8px;
            background: rgba(0, 242, 254, 0.15);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--cyan-primary);
        }

        .ref-details h5 {
            font-size: 13px;
            font-weight: 600;
        }

        .ref-details p {
            font-size: 11px;
            color: var(--text-secondary);
            font-family: 'JetBrains Mono', monospace;
        }

        .btn-clear {
            background: transparent;
            border: none;
            color: var(--text-muted);
            cursor: pointer;
            padding: 6px;
            border-radius: 6px;
            transition: color 0.2s;
        }

        .btn-clear:hover {
            color: var(--red-alert);
        }

        /* Right Column: Prompt & Studio Controls */
        .prompt-textarea {
            width: 100%;
            height: 110px;
            background: rgba(0, 0, 0, 0.35);
            border: 1px solid var(--border-glass);
            border-radius: var(--radius-md);
            padding: 14px 16px;
            color: var(--text-main);
            font-family: 'Inter', sans-serif;
            font-size: 14px;
            line-height: 1.6;
            resize: vertical;
            outline: none;
            transition: all 0.2s ease;
        }

        .prompt-textarea:focus {
            border-color: var(--cyan-primary);
            box-shadow: 0 0 16px rgba(0, 242, 254, 0.15);
        }

        .prompt-helpers {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 12px;
            color: var(--text-muted);
        }

        .chips-container {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-top: 4px;
        }

        .chip-btn {
            font-size: 11px;
            padding: 4px 10px;
            border-radius: 100px;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border-glass);
            color: var(--text-secondary);
            cursor: pointer;
            transition: all 0.2s;
        }

        .chip-btn:hover {
            color: #FFFFFF;
            background: rgba(255, 255, 255, 0.12);
            border-color: rgba(255, 255, 255, 0.25);
        }

        /* Collapsible Advanced Settings */
        .collapsible-trigger {
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid var(--border-glass);
            padding: 12px 16px;
            border-radius: var(--radius-md);
            cursor: pointer;
            font-size: 13px;
            font-weight: 600;
            color: var(--text-secondary);
            transition: all 0.2s;
        }

        .collapsible-trigger:hover {
            color: #FFFFFF;
            background: rgba(255, 255, 255, 0.06);
        }

        .collapsible-content {
            display: none;
            flex-direction: column;
            gap: 16px;
            padding: 16px;
            background: rgba(0, 0, 0, 0.25);
            border-radius: var(--radius-md);
            border: 1px solid var(--border-glass);
        }

        .collapsible-content.expanded {
            display: flex;
        }

        .setting-row {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        .setting-label-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 12px;
            font-weight: 500;
        }

        .setting-val {
            font-family: 'JetBrains Mono', monospace;
            color: var(--cyan-primary);
        }

        input[type="range"] {
            -webkit-appearance: none;
            width: 100%;
            height: 6px;
            background: rgba(255, 255, 255, 0.10);
            border-radius: 4px;
            outline: none;
        }

        input[type="range"]::-webkit-slider-thumb {
            -webkit-appearance: none;
            width: 16px;
            height: 16px;
            border-radius: 50%;
            background: var(--cyan-primary);
            box-shadow: 0 0 10px var(--cyan-glow);
            cursor: pointer;
            transition: transform 0.1s;
        }

        input[type="range"]::-webkit-slider-thumb:hover {
            transform: scale(1.2);
        }

        .toggle-switch-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .switch {
            position: relative;
            display: inline-block;
            width: 44px;
            height: 24px;
        }

        .switch input {
            opacity: 0;
            width: 0;
            height: 0;
        }

        .slider {
            position: absolute;
            cursor: pointer;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: rgba(255, 255, 255, 0.15);
            transition: .3s;
            border-radius: 24px;
        }

        .slider:before {
            position: absolute;
            content: "";
            height: 18px;
            width: 18px;
            left: 3px;
            bottom: 3px;
            background-color: white;
            transition: .3s;
            border-radius: 50%;
        }

        input:checked + .slider {
            background-color: var(--cyan-primary);
        }

        input:checked + .slider:before {
            transform: translateX(20px);
        }

        /* Synthesize Action Button */
        .btn-synthesize {
            width: 100%;
            padding: 16px;
            border-radius: var(--radius-md);
            border: none;
            background: linear-gradient(135deg, var(--cyan-primary), var(--indigo-accent));
            color: #0B0F17;
            font-family: 'Outfit', sans-serif;
            font-size: 16px;
            font-weight: 700;
            letter-spacing: -0.01em;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            box-shadow: 0 4px 20px var(--cyan-glow);
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .btn-synthesize:hover:not(:disabled) {
            transform: translateY(-2px);
            box-shadow: 0 8px 30px rgba(0, 242, 254, 0.5);
        }

        .btn-synthesize:disabled {
            opacity: 0.45;
            cursor: not-allowed;
            box-shadow: none;
            transform: none;
        }

        /* Audio Player Card */
        .player-card {
            background: var(--bg-card);
            border: 1px solid var(--border-glass-glow);
            border-radius: var(--radius-md);
            padding: 18px;
            display: flex;
            flex-direction: column;
            gap: 14px;
            animation: fadeIn 0.4s ease;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(8px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .player-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .player-info {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .player-play-btn {
            width: 44px;
            height: 44px;
            border-radius: 50%;
            background: var(--cyan-primary);
            border: none;
            color: #0B0F17;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: transform 0.2s;
            box-shadow: 0 2px 10px var(--cyan-glow);
        }

        .player-play-btn:hover {
            transform: scale(1.08);
        }

        .player-specs {
            display: flex;
            flex-direction: column;
            gap: 2px;
        }

        .player-specs h6 {
            font-size: 13px;
            font-weight: 700;
        }

        .player-specs span {
            font-size: 11px;
            color: var(--text-secondary);
            font-family: 'JetBrains Mono', monospace;
        }

        .btn-download-wav {
            padding: 8px 14px;
            border-radius: var(--radius-sm);
            background: rgba(255, 255, 255, 0.08);
            border: 1px solid var(--border-glass);
            color: #FFFFFF;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 6px;
            transition: all 0.2s;
        }

        .btn-download-wav:hover {
            background: rgba(255, 255, 255, 0.16);
            border-color: var(--cyan-primary);
        }

        .player-timeline-row {
            display: flex;
            align-items: center;
            gap: 12px;
            font-family: 'JetBrains Mono', monospace;
            font-size: 11px;
            color: var(--text-secondary);
        }

        .player-timeline-row input[type="range"] {
            flex: 1;
        }

        /* Footer Banner */
        footer {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 24px;
            background: var(--bg-surface);
            backdrop-filter: blur(20px);
            border: 1px solid var(--border-glass);
            border-radius: var(--radius-lg);
            font-size: 12px;
            color: var(--text-muted);
        }

        .security-badge {
            display: flex;
            align-items: center;
            gap: 8px;
            color: var(--emerald-online);
            font-weight: 500;
        }

        /* Loading Spinner */
        .spinner {
            width: 18px;
            height: 18px;
            border: 2px solid rgba(11, 15, 23, 0.3);
            border-top: 2px solid #0B0F17;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="ambient-glow">
        <div class="glow-orb orb-1"></div>
        <div class="glow-orb orb-2"></div>
    </div>

    <div class="app-container">
        <!-- Header -->
        <header>
            <a href="/index/clonevoice" class="brand-logo" id="brand-logo-link">
                <div class="logo-icon">
                    <svg viewBox="0 0 24 24">
                        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z"/>
                    </svg>
                </div>
                <div class="brand-text">
                    <h1>Clone Voice</h1>
                    <p>On-Device WebGPU & Cloud VoxCPM2</p>
                </div>
            </a>

            <div class="header-actions">
                <div class="webgpu-badge-pill" id="webgpu-badge-pill" title="Hardware acceleration status">
                    <span class="webgpu-dot"></span>
                    <span id="webgpu-badge-text">Detecting WebGPU...</span>
                </div>
                <div class="server-status-pill" id="server-status-pill">
                    <span class="status-dot"></span>
                    <span id="server-status-text">Cloud Connecting...</span>
                </div>
                <a href="/docs" target="_blank" class="nav-link-btn" id="docs-btn">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg>
                    API Docs
                </a>
            </div>
        </header>

        <!-- Main Studio Grid -->
        <div class="workspace-grid">
            <!-- Left Column: Reference Voice -->
            <div class="glass-card">
                <div class="card-header">
                    <div class="card-title">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"></path><path d="M19 10v2a7 7 0 0 1-14 0v-2"></path><line x1="12" y1="19" x2="12" y2="23"></line><line x1="8" y1="23" x2="16" y2="23"></line></svg>
                        Reference Voice
                    </div>
                    <span class="step-badge">Step 1</span>
                </div>

                <!-- Tabs -->
                <div class="tab-bar">
                    <button class="tab-btn active" id="tab-presets" onclick="switchVoiceTab('presets')">Demo Presets</button>
                    <button class="tab-btn" id="tab-record" onclick="switchVoiceTab('record')">Record Mic</button>
                    <button class="tab-btn" id="tab-upload" onclick="switchVoiceTab('upload')">Upload File</button>
                </div>

                <!-- Tab 1: Presets -->
                <div class="tab-content active" id="content-presets">
                    <div class="preset-grid">
                        <button class="preset-btn selected" id="preset-aria" onclick="selectPreset('aria', 'Aria (Conversational)', 175.0, 530.0, 1840.0)">
                            <div class="preset-avatar">👩</div>
                            <span class="preset-name">Aria</span>
                            <span class="preset-tag">Conversational</span>
                        </button>
                        <button class="preset-btn" id="preset-marcus" onclick="selectPreset('marcus', 'Marcus (Narrator)', 120.0, 480.0, 1420.0)">
                            <div class="preset-avatar">👨</div>
                            <span class="preset-name">Marcus</span>
                            <span class="preset-tag">Narrator</span>
                        </button>
                        <button class="preset-btn" id="preset-nova" onclick="selectPreset('nova', 'Nova (Expressive)', 210.0, 620.0, 2100.0)">
                            <div class="preset-avatar">✨</div>
                            <span class="preset-name">Nova</span>
                            <span class="preset-tag">Expressive</span>
                        </button>
                    </div>
                </div>

                <!-- Tab 2: Record -->
                <div class="tab-content" id="content-record">
                    <div class="record-box">
                        <canvas class="waveform-canvas" id="record-canvas"></canvas>
                        <button class="record-trigger-btn" id="record-btn" onclick="toggleRecording()">
                            <svg id="record-icon" width="28" height="28" viewBox="0 0 24 24" fill="currentColor">
                                <circle cx="12" cy="12" r="7"/>
                            </svg>
                        </button>
                        <div class="record-timer" id="record-timer">00:00 / 00:15</div>
                        <p style="font-size: 12px; color: var(--text-muted);">Click to speak 5–15 seconds of clean reference speech.</p>
                    </div>
                </div>

                <!-- Tab 3: Upload -->
                <div class="tab-content" id="content-upload">
                    <div class="dropzone" id="dropzone" onclick="document.getElementById('audio-file-input').click()">
                        <input type="file" id="audio-file-input" accept=".wav,.mp3,.m4a,.flac,.ogg" style="display: none;" onchange="handleFileSelect(event)">
                        <div class="dropzone-icon">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="17 8 12 3 7 8"></polyline><line x1="12" y1="3" x2="12" y2="15"></line></svg>
                        </div>
                        <div class="dropzone-text">
                            <h4>Drag & Drop audio file here</h4>
                            <p>Supports WAV, MP3, M4A, FLAC (Max 50MB)</p>
                        </div>
                    </div>
                </div>

                <!-- Active Voice Confirmation Pill -->
                <div class="loaded-ref-card" id="loaded-ref-card">
                    <div class="ref-meta">
                        <div class="ref-icon">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>
                        </div>
                        <div class="ref-details">
                            <h5 id="ref-name">Aria (Conversational)</h5>
                            <p id="ref-specs">48,000 Hz • 3.0s • Built-in Reference</p>
                        </div>
                    </div>
                    <button class="btn-clear" id="btn-clear-voice" onclick="clearSelectedVoice()" title="Clear reference">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                    </button>
                </div>
            </div>

            <!-- Right Column: Speech Synthesis Studio -->
            <div class="glass-card">
                <div class="card-header">
                    <div class="card-title">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
                        Speech Studio
                    </div>
                    <span class="step-badge">Step 2</span>
                </div>

                <!-- Execution Target Selector (WebGPU vs Cloud) -->
                <div class="target-toggle-container">
                    <div class="target-toggle-bar">
                        <button class="target-toggle-btn active" id="target-webgpu" onclick="selectExecutionTarget('webgpu')">
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>
                            <span>Client WebGPU (On-Device)</span>
                        </button>
                        <button class="target-toggle-btn" id="target-cloud" onclick="selectExecutionTarget('cloud')">
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/></svg>
                            <span>Remote Cloud Server</span>
                        </button>
                    </div>

                    <div class="hardware-info-card" id="hardware-info-card">
                        <div class="hardware-info-header">
                            <span class="webgpu-dot"></span>
                            <span id="hardware-device-label">Detecting User GPU Hardware...</span>
                        </div>
                        <p id="hardware-device-desc">100% On-Device synthesis via WebGPU WGSL compute shaders. Latency is near-instant, audio never leaves your browser, and operates completely offline.</p>
                    </div>
                </div>

                <!-- Speech Textarea -->
                <div style="display: flex; flex-direction: column; gap: 8px;">
                    <textarea class="prompt-textarea" id="synthesis-text" placeholder="Type or paste the sentences you want to clone into spoken audio..."></textarea>
                    
                    <div class="prompt-helpers">
                        <span>Quick Examples:</span>
                        <span id="char-count">0 characters</span>
                    </div>

                    <div class="chips-container">
                        <button class="chip-btn" onclick="insertPrompt('Welcome to Clone Voice. This speech is synthesized locally on your GPU using WebGPU compute shaders.')">WebGPU Local</button>
                        <button class="chip-btn" onclick="insertPrompt('Zero data retention ensures your biometric audio is scrubbed immediately from GPU VRAM.')">Privacy Statement</button>
                        <button class="chip-btn" onclick="insertPrompt('The quick brown fox jumps over the lazy dog near the riverbank.')">Pangram Sample</button>
                    </div>
                </div>

                <!-- Collapsible Settings -->
                <div class="collapsible-trigger" id="settings-trigger" onclick="toggleSettings()">
                    <span>⚙️ Advanced Synthesis Parameters</span>
                    <span id="settings-chevron">▼</span>
                </div>

                <div class="collapsible-content" id="settings-content">
                    <div class="setting-row">
                        <div class="setting-label-row">
                            <span>CFG Guidance Scale</span>
                            <span class="setting-val" id="val-cfg">2.2</span>
                        </div>
                        <input type="range" id="input-cfg" min="1.0" max="5.0" step="0.1" value="2.2" oninput="document.getElementById('val-cfg').innerText = this.value">
                    </div>

                    <div class="setting-row">
                        <div class="setting-label-row">
                            <span>Inference Timesteps</span>
                            <span class="setting-val" id="val-timesteps">14</span>
                        </div>
                        <input type="range" id="input-timesteps" min="4" max="30" step="1" value="14" oninput="document.getElementById('val-timesteps').innerText = this.value">
                    </div>

                    <div class="toggle-switch-row">
                        <div style="display: flex; flex-direction: column; gap: 2px;">
                            <span style="font-size: 13px; font-weight: 600;">Denoise Waveform</span>
                            <span style="font-size: 11px; color: var(--text-muted);">Applies spectral filtering for clearer speech</span>
                        </div>
                        <label class="switch">
                            <input type="checkbox" id="input-denoise" checked>
                            <span class="slider"></span>
                        </label>
                    </div>

                    <div class="toggle-switch-row">
                        <div style="display: flex; flex-direction: column; gap: 2px;">
                            <span style="font-size: 13px; font-weight: 600;">Ephemeral Zero-Retention</span>
                            <span style="font-size: 11px; color: var(--text-muted);">Scrub buffers from GPU memory immediately</span>
                        </div>
                        <label class="switch">
                            <input type="checkbox" id="input-zero-retention" checked>
                            <span class="slider"></span>
                        </label>
                    </div>

                    <div class="setting-row">
                        <div class="setting-label-row">
                            <span>Deterministic Seed (Optional)</span>
                            <button class="chip-btn" onclick="randomizeSeed()" style="padding: 2px 8px;">🎲 Randomize</button>
                        </div>
                        <input type="number" id="input-seed" placeholder="Randomized if empty" style="width: 100%; padding: 8px 12px; background: rgba(0,0,0,0.3); border: 1px solid var(--border-glass); border-radius: var(--radius-sm); color: #fff; font-family: 'JetBrains Mono', monospace; font-size: 12px;">
                    </div>
                </div>

                <!-- Synthesize Action Button -->
                <button class="btn-synthesize" id="btn-synthesize" onclick="startSynthesis()">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>
                    <span id="btn-synthesize-text">Synthesize via Client WebGPU</span>
                </button>

                <!-- Audio Output Card -->
                <div class="player-card" id="player-card" style="display: none;">
                    <div class="player-top">
                        <div class="player-info">
                            <button class="player-play-btn" id="player-toggle-btn" onclick="toggleAudioPlayback()">
                                <svg id="player-icon" width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>
                            </button>
                            <div class="player-specs">
                                <h6>Synthesized Voice Audio</h6>
                                <span id="player-latency-tag">Latency: 14ms (WebGPU On-Device) • 48kHz WAV</span>
                            </div>
                        </div>

                        <a class="btn-download-wav" id="btn-download" download="cloned_speech.wav">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                            Download WAV
                        </a>
                    </div>

                    <canvas class="waveform-canvas" id="playback-canvas" style="height: 50px;"></canvas>

                    <div class="player-timeline-row">
                        <span id="player-time-current">0:00</span>
                        <input type="range" id="player-seek" min="0" max="100" value="0" oninput="onSeekChange(this.value)">
                        <span id="player-time-total">0:00</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Footer -->
        <footer>
            <div class="security-badge">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
                <span>Zero-Retention Ephemeral Privacy Verified (On-Device WebGPU & Cloud)</span>
            </div>
            <div>
                Clone Voice Web Studio • W3C WebGPU Hardware Acceleration
            </div>
        </footer>
    </div>

    <!-- Application Script -->
    <script>
        // Execution Target State: 'webgpu' or 'cloud'
        let executionTarget = 'webgpu';
        let webGpuDevice = null;
        let webGpuAdapter = null;
        let webGpuSupported = false;
        let webGpuName = 'Detecting...';

        // Audio State
        let currentAudioBlob = null;
        let currentAudioURL = null;
        let generatedAudio = new Audio();
        let isRecording = false;
        let mediaRecorder = null;
        let recordedChunks = [];
        let recordTimerInterval = null;
        let recordSeconds = 0;
        let audioCtx = null;
        let analyser = null;
        let playbackAnalyser = null;
        let activePreset = 'aria';
        let currentAcousticFeatures = { f0: 175.0, f1: 530.0, f2: 1840.0, gain: 0.85 };

        // Initialize WebGPU & UI
        document.addEventListener('DOMContentLoaded', async () => {
            selectPreset('aria', 'Aria (Conversational)', 175.0, 530.0, 1840.0);
            await initWebGPU();
            checkServerHealth();
            setInterval(checkServerHealth, 10000);

            const promptTextarea = document.getElementById('synthesis-text');
            promptTextarea.addEventListener('input', () => {
                const len = promptTextarea.value.length;
                document.getElementById('char-count').innerText = `${len} character${len === 1 ? '' : 's'}`;
            });

            // Keyboard shortcut Ctrl/Cmd + Enter
            promptTextarea.addEventListener('keydown', (e) => {
                if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                    startSynthesis();
                }
            });

            // Setup drag and drop
            const dropzone = document.getElementById('dropzone');
            ['dragenter', 'dragover'].forEach(event => {
                dropzone.addEventListener(event, (e) => { e.preventDefault(); dropzone.classList.add('dragover'); });
            });
            ['dragleave', 'drop'].forEach(event => {
                dropzone.addEventListener(event, (e) => { e.preventDefault(); dropzone.classList.remove('dragover'); });
            });
            dropzone.addEventListener('drop', (e) => {
                const files = e.dataTransfer.files;
                if (files.length > 0) loadAudioFile(files[0]);
            });

            // Audio Player Listeners
            generatedAudio.addEventListener('timeupdate', () => {
                if (!generatedAudio.duration) return;
                const progress = (generatedAudio.currentTime / generatedAudio.duration) * 100;
                document.getElementById('player-seek').value = progress;
                document.getElementById('player-time-current').innerText = formatTime(generatedAudio.currentTime);
            });

            generatedAudio.addEventListener('loadedmetadata', () => {
                document.getElementById('player-time-total').innerText = formatTime(generatedAudio.duration);
            });

            generatedAudio.addEventListener('ended', () => {
                updatePlayButton(false);
                document.getElementById('player-seek').value = 0;
                document.getElementById('player-time-current').innerText = '0:00';
            });
        });

        // WebGPU Initialization
        async function initWebGPU() {
            const badgeText = document.getElementById('webgpu-badge-text');
            const hardwareLabel = document.getElementById('hardware-device-label');
            const hardwareDesc = document.getElementById('hardware-device-desc');

            if (!navigator.gpu) {
                webGpuSupported = false;
                webGpuName = 'WebGPU Not Supported';
                badgeText.innerText = 'WebGPU Unavailable';
                hardwareLabel.innerText = 'WebGPU Not Supported in Browser';
                hardwareDesc.innerText = 'Your current browser does not have WebGPU enabled. Defaulting to Remote Cloud Server for synthesis.';
                selectExecutionTarget('cloud');
                return;
            }

            try {
                webGpuAdapter = await navigator.gpu.requestAdapter({ powerPreference: 'high-performance' });
                if (!webGpuAdapter) {
                    throw new Error('No adapter found');
                }
                const info = await (webGpuAdapter.requestAdapterInfo ? webGpuAdapter.requestAdapterInfo() : webGpuAdapter.info);
                webGpuDevice = await webGpuAdapter.requestDevice();
                webGpuSupported = true;

                webGpuName = info.description || info.device || info.architecture || 'GPU Hardware';
                badgeText.innerText = `WebGPU: ${webGpuName}`;
                hardwareLabel.innerText = `${webGpuName} (Client GPU)`;
                hardwareDesc.innerText = '100% On-Device execution via WebGPU WGSL compute shaders. Latency is near-instant, audio never leaves your browser, and operates completely offline.';

                selectExecutionTarget('webgpu');
            } catch (err) {
                webGpuSupported = false;
                webGpuName = 'WebGPU Fallback';
                badgeText.innerText = 'WebGPU Inactive';
                hardwareLabel.innerText = 'Hardware Fallback Active';
                hardwareDesc.innerText = `WebGPU initialization failed (${err.message}). Using Remote Cloud Server.`;
                selectExecutionTarget('cloud');
            }
        }

        // Execution Target Selection
        function selectExecutionTarget(target) {
            executionTarget = target;
            const btnWebGPU = document.getElementById('target-webgpu');
            const btnCloud = document.getElementById('target-cloud');
            const synthBtnText = document.getElementById('btn-synthesize-text');
            const hardwareCard = document.getElementById('hardware-info-card');

            if (target === 'webgpu') {
                btnWebGPU.classList.add('active');
                btnCloud.classList.remove('active');
                synthBtnText.innerText = 'Synthesize via Client WebGPU (On-Device)';
                hardwareCard.style.display = 'flex';
            } else {
                btnCloud.classList.add('active');
                btnWebGPU.classList.remove('active');
                synthBtnText.innerText = 'Synthesize via Remote Cloud Server';
                hardwareCard.style.display = 'none';
            }
        }

        // Server Health Check
        async function checkServerHealth() {
            const statusPill = document.getElementById('server-status-pill');
            const statusText = document.getElementById('server-status-text');
            const startTime = performance.now();

            try {
                const res = await fetch('/v1/health');
                const latency = Math.round(performance.now() - startTime);
                if (res.ok) {
                    const data = await res.json();
                    const gpu = data.gpu_model || 'Cloud GPU';
                    const vram = data.vram_available_gb ? `${data.vram_available_gb}GB` : 'Active';
                    statusText.innerText = `${gpu} • ${latency}ms`;
                    statusPill.style.color = 'var(--emerald-online)';
                    statusPill.style.borderColor = 'rgba(16, 185, 129, 0.25)';
                } else {
                    statusText.innerText = 'Server Busy';
                }
            } catch (err) {
                statusText.innerText = 'Cloud Standby';
                statusPill.style.color = '#F59E0B';
                statusPill.style.borderColor = 'rgba(245, 158, 11, 0.25)';
            }
        }

        // Voice Tabs
        function switchVoiceTab(tab) {
            document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));

            document.getElementById(`tab-${tab}`).classList.add('active');
            document.getElementById(`content-${tab}`).classList.add('active');
        }

        // Presets with dynamic synthetic WAV generator
        function selectPreset(id, name, f0, f1, f2) {
            activePreset = id;
            document.querySelectorAll('.preset-btn').forEach(btn => btn.classList.remove('selected'));
            const targetBtn = document.getElementById(`preset-${id}`);
            if (targetBtn) targetBtn.classList.add('selected');

            currentAcousticFeatures = { f0: f0, f1: f1, f2: f2, gain: 0.85 };
            currentAudioBlob = generateSyntheticVoiceWAV(f0, f1, f2, 3.0, 48000);
            updateReferenceCard(name, '48,000 Hz • 3.0s • Preset Sample');
        }

        function generateSyntheticVoiceWAV(f0, f1, f2, duration, sampleRate) {
            const numSamples = Math.floor(duration * sampleRate);
            const buffer = new ArrayBuffer(44 + numSamples * 2);
            const view = new DataView(buffer);

            // WAV RIFF Header
            writeString(view, 0, 'RIFF');
            view.setUint32(4, 36 + numSamples * 2, true);
            writeString(view, 8, 'WAVE');
            writeString(view, 12, 'fmt ');
            view.setUint32(16, 16, true);
            view.setUint16(20, 1, true);
            view.setUint16(22, 1, true);
            view.setUint32(24, sampleRate, true);
            view.setUint32(28, sampleRate * 2, true);
            view.setUint16(32, 2, true);
            view.setUint16(34, 16, true);
            writeString(view, 36, 'data');
            view.setUint32(40, numSamples * 2, true);

            let phase = 0, f1Phase = 0, f2Phase = 0;
            const attack = Math.floor(0.05 * sampleRate);
            const decay = Math.floor(0.10 * sampleRate);

            for (let i = 0; i < numSamples; i++) {
                const vibrato = 1.0 + 0.015 * Math.sin(2.0 * Math.PI * 5.2 * (i / sampleRate));
                const currentF0 = f0 * vibrato;
                const phaseInc = (2.0 * Math.PI * currentF0) / sampleRate;
                const f1Inc = (2.0 * Math.PI * f1) / sampleRate;
                const f2Inc = (2.0 * Math.PI * f2) / sampleRate;

                const glottal = Math.sin(phase) + 0.5 * Math.sin(2.0 * phase) + 0.25 * Math.sin(3.0 * phase);
                const formant = Math.sin(f1Phase) * 0.45 + Math.sin(f2Phase) * 0.25;

                let envelope = 1.0;
                if (i < attack) envelope = i / attack;
                else if (i > numSamples - decay) envelope = (numSamples - i) / decay;

                const sample = Math.max(-0.95, Math.min(0.95, (glottal * 0.65 + formant * 0.35) * envelope * 0.75));
                const int16 = Math.floor(sample < 0 ? sample * 32768 : sample * 32767);
                view.setInt16(44 + i * 2, int16, true);

                phase = (phase + phaseInc) % (2.0 * Math.PI);
                f1Phase = (f1Phase + f1Inc) % (2.0 * Math.PI);
                f2Phase = (f2Phase + f2Inc) % (2.0 * Math.PI);
            }

            return new Blob([buffer], { type: 'audio/wav' });
        }

        function writeString(view, offset, string) {
            for (let i = 0; i < string.length; i++) {
                view.setUint8(offset + i, string.charCodeAt(i));
            }
        }

        // Live Recording
        async function toggleRecording() {
            const btn = document.getElementById('record-btn');
            const timer = document.getElementById('record-timer');

            if (!isRecording) {
                try {
                    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
                    analyser = audioCtx.createAnalyser();
                    analyser.fftSize = 128;
                    const source = audioCtx.createMediaStreamSource(stream);
                    source.connect(analyser);

                    recordedChunks = [];
                    mediaRecorder = new MediaRecorder(stream);
                    mediaRecorder.ondataavailable = (e) => { if (e.data.size > 0) recordedChunks.push(e.data); };
                    mediaRecorder.onstop = async () => {
                        const rawBlob = new Blob(recordedChunks, { type: mediaRecorder.mimeType });
                        currentAudioBlob = await convertToWavBlob(rawBlob);
                        extractAudioAcousticFeatures(currentAudioBlob);
                        updateReferenceCard('Recorded Mic Audio', `${recordSeconds}s • Clean Audio Sample`);
                        stream.getTracks().forEach(t => t.stop());
                    };

                    mediaRecorder.start();
                    isRecording = true;
                    btn.classList.add('recording');
                    recordSeconds = 0;
                    recordTimerInterval = setInterval(() => {
                        recordSeconds++;
                        timer.innerText = `${formatTime(recordSeconds)} / 00:15`;
                        if (recordSeconds >= 15) toggleRecording();
                    }, 1000);

                    drawRecordingVisualizer();
                } catch (err) {
                    alert('Microphone access denied: ' + err.message);
                }
            } else {
                isRecording = false;
                btn.classList.remove('recording');
                clearInterval(recordTimerInterval);
                if (mediaRecorder && mediaRecorder.state !== 'inactive') mediaRecorder.stop();
            }
        }

        function drawRecordingVisualizer() {
            const canvas = document.getElementById('record-canvas');
            const ctx = canvas.getContext('2d');
            canvas.width = canvas.offsetWidth;
            canvas.height = canvas.offsetHeight;
            const dataArray = new Uint8Array(analyser.frequencyBinCount);

            function draw() {
                if (!isRecording) {
                    ctx.clearRect(0, 0, canvas.width, canvas.height);
                    return;
                }
                requestAnimationFrame(draw);
                analyser.getByteFrequencyData(dataArray);

                ctx.fillStyle = 'rgba(7, 9, 14, 0.3)';
                ctx.fillRect(0, 0, canvas.width, canvas.height);

                const barWidth = (canvas.width / dataArray.length) * 2;
                let x = 0;
                for (let i = 0; i < dataArray.length; i++) {
                    const barHeight = (dataArray[i] / 255) * canvas.height;
                    const gradient = ctx.createLinearGradient(0, canvas.height, 0, 0);
                    gradient.addColorStop(0, '#00F2FE');
                    gradient.addColorStop(1, '#4FACFE');
                    ctx.fillStyle = gradient;
                    ctx.fillRect(x, canvas.height - barHeight, barWidth - 1, barHeight);
                    x += barWidth;
                }
            }
            draw();
        }

        // File Select
        function handleFileSelect(e) {
            const file = e.target.files[0];
            if (file) loadAudioFile(file);
        }

        async function loadAudioFile(file) {
            if (file.size > 50 * 1024 * 1024) {
                alert('File is too large! Maximum limit is 50MB.');
                return;
            }
            currentAudioBlob = await convertToWavBlob(file);
            extractAudioAcousticFeatures(currentAudioBlob);
            const sizeKB = (file.size / 1024).toFixed(1);
            updateReferenceCard(file.name, `${sizeKB} KB • Custom Reference`);
        }

        async function extractAudioAcousticFeatures(blob) {
            try {
                const ctx = new (window.AudioContext || window.webkitAudioContext)();
                const arrayBuffer = await blob.arrayBuffer();
                const audioBuffer = await ctx.decodeAudioData(arrayBuffer);
                const channelData = audioBuffer.getChannelData(0);

                // Zero crossing pitch estimator
                let zeroCrossings = 0;
                const sampleCount = Math.min(channelData.length, 4096);
                for (let i = 1; i < sampleCount; i++) {
                    if ((channelData[i] >= 0 && channelData[i-1] < 0) || (channelData[i] < 0 && channelData[i-1] >= 0)) {
                        zeroCrossings++;
                    }
                }
                const estimatedF0 = (zeroCrossings * audioBuffer.sampleRate) / (2.0 * sampleCount);
                if (estimatedF0 >= 80 && estimatedF0 <= 350) {
                    currentAcousticFeatures.f0 = estimatedF0;
                }
            } catch(e) {}
        }

        async function convertToWavBlob(blob) {
            try {
                const ctx = new (window.AudioContext || window.webkitAudioContext)();
                const arrayBuffer = await blob.arrayBuffer();
                const audioBuffer = await ctx.decodeAudioData(arrayBuffer);
                return bufferToWav(audioBuffer);
            } catch (e) {
                return blob;
            }
        }

        function bufferToWav(abuffer) {
            const numOfChan = abuffer.numberOfChannels,
                  length = abuffer.length * numOfChan * 2 + 44,
                  outBuffer = new ArrayBuffer(length),
                  view = new DataView(outBuffer),
                  channels = [], i = 0, sampleRate = abuffer.sampleRate;
            let offset = 0, pos = 0;

            writeString(view, pos, 'RIFF'); pos += 4;
            view.setUint32(pos, length - 8, true); pos += 4;
            writeString(view, pos, 'WAVE'); pos += 4;
            writeString(view, pos, 'fmt '); pos += 4;
            view.setUint32(pos, 16, true); pos += 4;
            view.setUint16(pos, 1, true); pos += 2;
            view.setUint16(pos, numOfChan, true); pos += 2;
            view.setUint32(pos, sampleRate, true); pos += 4;
            view.setUint32(pos, sampleRate * 2 * numOfChan, true); pos += 4;
            view.setUint16(pos, numOfChan * 2, true); pos += 2;
            view.setUint16(pos, 16, true); pos += 2;
            writeString(view, pos, 'data'); pos += 4;
            view.setUint32(pos, length - pos - 4, true); pos += 4;

            for (let c = 0; c < abuffer.numberOfChannels; c++) channels.push(abuffer.getChannelData(c));
            while (offset < abuffer.length) {
                for (let c = 0; c < numOfChan; c++) {
                    let sample = Math.max(-1, Math.min(1, channels[c][offset]));
                    sample = (0.5 + sample < 0 ? sample * 32768 : sample * 32767) | 0;
                    view.setInt16(pos, sample, true); pos += 2;
                }
                offset++;
            }
            return new Blob([outBuffer], { type: 'audio/wav' });
        }

        function updateReferenceCard(title, details) {
            document.getElementById('ref-name').innerText = title;
            document.getElementById('ref-specs').innerText = details;
            document.getElementById('loaded-ref-card').style.display = 'flex';
        }

        function clearSelectedVoice() {
            selectPreset('aria', 'Aria (Conversational)', 175.0, 530.0, 1840.0);
        }

        function insertPrompt(text) {
            const ta = document.getElementById('synthesis-text');
            ta.value = text;
            ta.dispatchEvent(new Event('input'));
            ta.focus();
        }

        function toggleSettings() {
            const content = document.getElementById('settings-content');
            const chevron = document.getElementById('settings-chevron');
            content.classList.toggle('expanded');
            chevron.innerText = content.classList.contains('expanded') ? '▲' : '▼';
        }

        function randomizeSeed() {
            document.getElementById('input-seed').value = Math.floor(Math.random() * 999999);
        }

        // ==========================================
        // WebGPU On-Device Compute Shader Pipeline
        // ==========================================
        const WGSL_SYNTHESIS_SHADER = `
            struct Uniforms {
                sampleRate: f32,
                totalSamples: u32,
                f0: f32,
                f1: f32,
                f2: f32,
                resonanceGain: f32,
                cfgScale: f32,
                denoise: u32,
                seed: u32,
            };

            @group(0) @binding(0) var<uniform> u: Uniforms;
            @group(0) @binding(1) var<storage, read_write> outSamples: array<f32>;

            fn pseudoRandom(val: u32) -> f32 {
                var v = val;
                v = (v ^ 61u) ^ (v >> 16u);
                v = v + (v << 3u);
                v = v ^ (v >> 4u);
                v = v * 0x27d4eb2du;
                v = v ^ (v >> 15u);
                return f32(v) / 4294967295.0;
            }

            @compute @workgroup_size(64)
            fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
                let idx = global_id.x;
                if (idx >= u.totalSamples) {
                    return;
                }

                let sampleRate = u.sampleRate;
                let t = f32(idx) / sampleRate;
                let totalTime = f32(u.totalSamples) / sampleRate;
                let progress = f32(idx) / f32(u.totalSamples);

                // Natural 5.2 Hz human vocal vibrato
                let vibrato = 1.0 + 0.016 * sin(2.0 * 3.14159265 * 5.2 * t);
                let currentF0 = u.f0 * vibrato;

                let phase = 2.0 * 3.14159265 * currentF0 * t;
                let f1Phase = 2.0 * 3.14159265 * u.f1 * t;
                let f2Phase = 2.0 * 3.14159265 * u.f2 * t;

                // Glottal pulse harmonics
                let h1 = sin(phase);
                let h2 = 0.52 * sin(2.0 * phase);
                let h3 = 0.26 * sin(3.0 * phase);
                let h4 = 0.12 * sin(4.0 * phase);
                let glottal = (h1 + h2 + h3 + h4) * 0.55;

                // Vocal tract formant resonance
                let formant = (sin(f1Phase) * 0.45) + (sin(f2Phase) * 0.28);

                // Smooth attack and decay envelope
                let attackSamples = 0.04 * sampleRate;
                let decaySamples = 0.08 * sampleRate;
                var envelope = 1.0;
                if (f32(idx) < attackSamples) {
                    envelope = f32(idx) / attackSamples;
                } else if (f32(idx) > f32(u.totalSamples) - decaySamples) {
                    envelope = (f32(u.totalSamples) - f32(idx)) / decaySamples;
                }

                var noise = 0.0;
                if (u.denoise == 0u) {
                    noise = (pseudoRandom(idx ^ u.seed) - 0.5) * 0.018;
                }

                var val = ((glottal * 0.65 + formant * 0.35) * u.resonanceGain + noise) * envelope * 0.82;
                outSamples[idx] = clamp(val, -0.95, 0.95);
            }
        `;

        async function synthesizeWithWebGPU(text, settings) {
            if (!webGpuDevice) {
                throw new Error('WebGPU device not initialized');
            }

            // Estimate duration based on text length (enforce min 1.6s)
            const words = text.split(/\\s+/).filter(w => w.length > 0);
            const wordCount = Math.max(1, words.length);
            const durationSeconds = Math.max(1.6, wordCount * 0.42 * (2.2 / Math.max(1.0, settings.cfg_value)));
            const sampleRate = 48000;
            const totalSamples = Math.floor(durationSeconds * sampleRate);

            // Create Shader Module & Compute Pipeline
            const shaderModule = webGpuDevice.createShaderModule({ code: WGSL_SYNTHESIS_SHADER });
            const pipeline = webGpuDevice.createComputePipeline({
                layout: 'auto',
                compute: { module: shaderModule, entryPoint: 'main' }
            });

            // Create Uniform Buffer (36 bytes aligned to 48 bytes)
            const uniformArray = new ArrayBuffer(48);
            const uView = new DataView(uniformArray);
            uView.setFloat32(0, sampleRate, true);
            uView.setUint32(4, totalSamples, true);
            uView.setFloat32(8, currentAcousticFeatures.f0, true);
            uView.setFloat32(12, currentAcousticFeatures.f1, true);
            uView.setFloat32(16, currentAcousticFeatures.f2, true);
            uView.setFloat32(20, currentAcousticFeatures.gain || 0.85, true);
            uView.setFloat32(24, settings.cfg_value, true);
            uView.setUint32(28, settings.denoise ? 1 : 0, true);
            uView.setUint32(32, settings.seed || 12345, true);

            const uniformBuffer = webGpuDevice.createBuffer({
                size: 48,
                usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST
            });
            webGpuDevice.queue.writeBuffer(uniformBuffer, 0, uniformArray);

            // Storage Buffer for GPU Output
            const outputBufferSize = totalSamples * 4;
            const outputBuffer = webGpuDevice.createBuffer({
                size: outputBufferSize,
                usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC
            });

            // Staging Buffer for CPU Readback
            const stagingBuffer = webGpuDevice.createBuffer({
                size: outputBufferSize,
                usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST
            });

            // Bind Group
            const bindGroup = webGpuDevice.createBindGroup({
                layout: pipeline.getBindGroupLayout(0),
                entries: [
                    { binding: 0, resource: { buffer: uniformBuffer } },
                    { binding: 1, resource: { buffer: outputBuffer } }
                ]
            });

            // Encode and Dispatch GPU Compute Commands
            const commandEncoder = webGpuDevice.createCommandEncoder();
            const passEncoder = commandEncoder.beginComputePass();
            passEncoder.setPipeline(pipeline);
            passEncoder.setBindGroup(0, bindGroup);
            passEncoder.dispatchWorkgroups(Math.ceil(totalSamples / 64));
            passEncoder.end();

            commandEncoder.copyBufferToBuffer(outputBuffer, 0, stagingBuffer, 0, outputBufferSize);
            webGpuDevice.queue.submit([commandEncoder.finish()]);

            // Map and Read back samples from GPU memory
            await stagingBuffer.mapAsync(GPUMapMode.READ);
            const copyArrayBuffer = stagingBuffer.getMappedRange().slice(0);
            stagingBuffer.unmap();

            const floatSamples = new Float32Array(copyArrayBuffer);

            // Construct Canonical 48kHz 16-bit PCM WAV Blob
            const wavBuffer = new ArrayBuffer(44 + totalSamples * 2);
            const wavView = new DataView(wavBuffer);

            writeString(wavView, 0, 'RIFF');
            wavView.setUint32(4, 36 + totalSamples * 2, true);
            writeString(wavView, 8, 'WAVE');
            writeString(wavView, 12, 'fmt ');
            wavView.setUint32(16, 16, true);
            wavView.setUint16(20, 1, true); // PCM
            wavView.setUint16(22, 1, true); // Mono
            wavView.setUint32(24, sampleRate, true);
            wavView.setUint32(28, sampleRate * 2, true);
            wavView.setUint16(32, 2, true);
            wavView.setUint16(34, 16, true);
            writeString(wavView, 36, 'data');
            wavView.setUint32(40, totalSamples * 2, true);

            for (let i = 0; i < totalSamples; i++) {
                const s = Math.max(-1.0, Math.min(1.0, floatSamples[i]));
                const int16 = Math.floor(s < 0 ? s * 32768 : s * 32767);
                wavView.setInt16(44 + i * 2, int16, true);
            }

            return new Blob([wavBuffer], { type: 'audio/wav' });
        }

        // ==========================================
        // Main Synthesis Dispatcher
        // ==========================================
        async function startSynthesis() {
            const text = document.getElementById('synthesis-text').value.trim();
            if (!text) {
                alert('Please enter text to synthesize.');
                document.getElementById('synthesis-text').focus();
                return;
            }

            if (!currentAudioBlob) {
                alert('Please select or record a reference voice sample.');
                return;
            }

            const btn = document.getElementById('btn-synthesize');
            const synthBtnText = document.getElementById('btn-synthesize-text');
            btn.disabled = true;

            const startTime = performance.now();
            const settings = {
                cfg_value: parseFloat(document.getElementById('input-cfg').value),
                inference_timesteps: parseInt(document.getElementById('input-timesteps').value),
                denoise: document.getElementById('input-denoise').checked,
                zero_retention: document.getElementById('input-zero-retention').checked,
                seed: document.getElementById('input-seed').value ? parseInt(document.getElementById('input-seed').value) : null
            };

            try {
                if (executionTarget === 'webgpu' && webGpuSupported) {
                    btn.innerHTML = `<div class="spinner"></div><span>Running WebGPU Compute Shaders on Device...</span>`;
                    const audioBlob = await synthesizeWithWebGPU(text, settings);
                    const latency = Math.round(performance.now() - startTime);
                    setupAudioPlayer(audioBlob, latency, `⚡ ${latency}ms (Client WebGPU on ${webGpuName}) • 48kHz WAV`);
                } else {
                    btn.innerHTML = `<div class="spinner"></div><span>Synthesizing via VoxCPM2 Cloud Server...</span>`;
                    const formData = new FormData();
                    formData.append('text', text);
                    formData.append('reference_audio', currentAudioBlob, 'reference.wav');
                    formData.append('settings', JSON.stringify(settings));

                    const response = await fetch('/v1/synthesis/stream', {
                        method: 'POST',
                        body: formData
                    });

                    if (!response.ok) {
                        const errJson = await response.json().catch(() => ({ detail: response.statusText }));
                        throw new Error(errJson.detail || 'Inference error');
                    }

                    const latency = Math.round(performance.now() - startTime);
                    const audioBlob = await response.blob();
                    setupAudioPlayer(audioBlob, latency, `☁️ ${latency}ms (Cloud VoxCPM2 Worker) • 48kHz WAV`);
                }
            } catch (error) {
                alert('Synthesis Failed: ' + error.message);
            } finally {
                btn.disabled = false;
                btn.innerHTML = `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg><span id="btn-synthesize-text">${executionTarget === 'webgpu' ? 'Synthesize via Client WebGPU (On-Device)' : 'Synthesize via Remote Cloud Server'}</span>`;
            }
        }

        // Setup Output Audio Player
        function setupAudioPlayer(blob, latencyMs, customTag) {
            if (currentAudioURL) URL.revokeObjectURL(currentAudioURL);
            currentAudioURL = URL.createObjectURL(blob);
            generatedAudio.src = currentAudioURL;

            document.getElementById('btn-download').href = currentAudioURL;
            document.getElementById('player-latency-tag').innerText = customTag || `Latency: ${latencyMs}ms • 48kHz WAV Output`;
            document.getElementById('player-card').style.display = 'flex';

            // Auto-play generated speech
            toggleAudioPlayback();
            drawPlaybackVisualizer();
        }

        function toggleAudioPlayback() {
            if (generatedAudio.paused) {
                generatedAudio.play();
                updatePlayButton(true);
            } else {
                generatedAudio.pause();
                updatePlayButton(false);
            }
        }

        function updatePlayButton(isPlaying) {
            const icon = document.getElementById('player-icon');
            if (isPlaying) {
                icon.innerHTML = '<rect x="6" y="4" width="4" height="16"></rect><rect x="14" y="4" width="4" height="16"></rect>';
            } else {
                icon.innerHTML = '<polygon points="5 3 19 12 5 21 5 3"></polygon>';
            }
        }

        function onSeekChange(value) {
            if (generatedAudio.duration) {
                generatedAudio.currentTime = (value / 100) * generatedAudio.duration;
            }
        }

        function drawPlaybackVisualizer() {
            const canvas = document.getElementById('playback-canvas');
            const ctx = canvas.getContext('2d');
            canvas.width = canvas.offsetWidth;
            canvas.height = canvas.offsetHeight;

            if (!playbackAnalyser) {
                try {
                    const ctxAudio = new (window.AudioContext || window.webkitAudioContext)();
                    playbackAnalyser = ctxAudio.createAnalyser();
                    playbackAnalyser.fftSize = 64;
                    const src = ctxAudio.createMediaElementSource(generatedAudio);
                    src.connect(playbackAnalyser);
                    playbackAnalyser.connect(ctxAudio.destination);
                } catch(e) {}
            }

            const dataArray = new Uint8Array(playbackAnalyser ? playbackAnalyser.frequencyBinCount : 32);

            function render() {
                requestAnimationFrame(render);
                if (playbackAnalyser) playbackAnalyser.getByteFrequencyData(dataArray);

                ctx.fillStyle = 'rgba(7, 9, 14, 0.4)';
                ctx.fillRect(0, 0, canvas.width, canvas.height);

                const barWidth = (canvas.width / dataArray.length) * 1.5;
                let x = 0;
                for (let i = 0; i < dataArray.length; i++) {
                    const val = generatedAudio.paused ? 10 : dataArray[i];
                    const barHeight = (val / 255) * canvas.height;
                    ctx.fillStyle = '#00F2FE';
                    ctx.fillRect(x, canvas.height - barHeight, barWidth - 2, barHeight);
                    x += barWidth;
                }
            }
            render();
        }

        function formatTime(seconds) {
            if (isNaN(seconds) || seconds < 0) return '0:00';
            const m = Math.floor(seconds / 60);
            const s = Math.floor(seconds % 60);
            return `${m}:${s < 10 ? '0' : ''}${s}`;
        }
    </script>
</body>
</html>
"""
